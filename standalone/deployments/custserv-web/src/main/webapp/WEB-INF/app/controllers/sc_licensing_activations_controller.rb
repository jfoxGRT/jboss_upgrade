require 'java'
import 'java.lang.Integer'
import 'java.lang.Character'
import 'java.util.HashMap'
begin
  import 'sami.web.SC'
  import 'sami.scholastic.messaging.MessageEventType'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
require 'sam_customer_manager/defaultDriver'

class ScLicensingActivationsController < TasksController
	
	before_filter :load_view_vars
	
	layout "default"
  
  SCHOOL_AUDIT_FAIL = "It appears that there are schools missing from your registered servers"
  LICENSE_AUDIT_FAIL = "It appears that there is a large discrepancy in your registered servers' license counts and the counts that Scholastic has on record"
	
	def assigned
		task_type = TaskType.find_by_code(TaskType.SC_LICENSING_ACTIVATION_CODE)
	    (redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
		@tasks = Task.find(:all, :select => "t.*, sp.name as state_name, sc.name as sam_customer_name, u.id as target_user_id, u.first_name, u.last_name", 
                        :joins => "t inner join state_province sp on t.state_province_id = sp.id 
                                   inner join sam_customer sc on t.sam_customer_id = sc.id
                                   inner join users u on t.current_user_id = u.id", 
                       :conditions => ["t.task_type_id = ? and t.status = 'a'", task_type.id])
		
	end
	
  
  
	def unassigned
		task_type = TaskType.find_by_code(TaskType.SC_LICENSING_ACTIVATION_CODE)
	    (redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
		conditions_clause = "t.task_type_id = ? and t.status = 'u' "
		conditions_fillins = [task_type.id]
		if (!params[:sam_customer_id].nil?)
			conditions_clause += "and t.sam_customer_id = ? "
			conditions_fillins << params[:sam_customer_id]
		end
	    @tasks = Task.find(:all, :select => "t.*, sp.name as state_name, sc.name as sam_customer_name", 
                        :joins => "t inner join state_province sp on t.state_province_id = sp.id
                                   inner join sam_customer sc on t.sam_customer_id = sc.id", 
                       :conditions => [conditions_clause, conditions_fillins].flatten, :order => "t.priority desc")
	end
  
  
  
  def edit
    @sam_customer = @task.sam_customer
    @org_details = Org.find_summary_details(@sam_customer.root_org.id)
	task_params = @task.task_params
	if (!task_params.detect{|tp| tp.name == 'userId'}.nil?)
    user_id = task_params.detect{|tp| tp.name == 'userId'}.value.to_i
    @requesting_user = (user_id.nil?) ? nil : User.find(user_id)
  else
    @requesting_user = nil
    @creator_name = task_params.detect{|tp| tp.name == 'userName'}
    @title = task_params.detect{|tp| tp.name == 'title'}
    @telephone_num = task_params.detect{|tp| tp.name == 'telephoneNum'}
  end    
	  @unmatched_schools = SamServerSchoolInfo.find_unmatched_schools(@sam_customer)
    @box_values = @task.task_params.select{|tp| tp.task_id=@task.id && tp.name='box'}.collect{|c| c.value.to_i}
  end
  
  def update
    sam_customer = @task.sam_customer
	  user_id = @task.current_user_id
    # if the third checkbox is set, then the LM activation request is granted
    if (params[:not_here] == "matched" && !params[:other_reason_checkbox])
		payload = {
                "sam_customer_id" => sam_customer.id,
                "user_id"  =>  user_id,
                "method_name" => 'complete_lm_opt_in_task'
      }
      logger.info("******Payload: " + payload.to_s)
      
      response = CustServServicesHandler.new.dynamic_edit_sam_customer(request.env['HTTP_HOST'],
                                                                   payload,
                                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_customer'] +
                                                                   "#{sam_customer.id}/license_manager/")
      if response
        if response.type == 'success'
          logger.debug("request to update sam customer #{@task.sam_customer.id.to_s} returned success.")
          logger.info("response >>>>>> #{response.to_s}")
          close_task(@task)
          flash[:notice] = (sam_customer.name + " is in the process of being activated for SC-Licensing")
        else
          logger.error "ERROR: request to update sam customer #{@task.sam_customer.id.to_s} returned failure: #{response.body || String.new}"  
        end  
      else logger.error("ERROR: no response from Web API call to update sam customer #{@task.sam_customer.id.to_s}.")
      end    
    
    # otherwise, the LM activation request is denied
    elsif (params[:other_reason_checkbox] && params[:not_here] == "matched")
      # due to a bug in google chrome and safari 4, we have to do a really lame check for an "other_reason" that is blank here
      raise ScLicensingActivationUpdateException.new(@task, flash, "You must provide a reason for this denial",
                  ScLicensingActivationUpdateException::BLANK_REASON) if (!params[:other_reason].nil? && params[:other_reason].strip.length < 3)
      # send the denied message here
      reasons = []
      # again, another lame check here due to chrome and safari 4 weirdness regarding <textarea>'s
      reasons << params[:other_reason] if (params[:other_reason] && params[:other_reason].strip.length >= 3)
      reasons_hash = Hash.new
      reasons.each_with_index do |r, index|
        reasons_hash[index] = r
      end  
      payload = {
                "sam_customer_id" => sam_customer.id,
                "user_id"  =>  user_id,
                "reasons_json" => reasons_hash.to_json,
                "task_id" => @task.id,
                "method_name" => 'reject_lm_opt_in_task'
      }
      logger.info("******Payload: " + payload.to_s)
      
      response = CustServServicesHandler.new.dynamic_edit_sam_customer(request.env['HTTP_HOST'],
                                                                   payload,
                                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_customer'] +
                                                                   "#{sam_customer.id}/license_manager/")
      if response
        if response.type == 'success'
          logger.debug("request to reject sam customer #{@task.sam_customer.id.to_s} returned success.")
          logger.info("response >>>>>> #{response.to_s}")  
          close_task(@task) 
          flash[:notice] = "License Manager request for #{sam_customer.name} rejected" 
        else
          logger.error "ERROR: request to update sam customer #{@task.sam_customer.id.to_s} returned failure: #{response.body || String.new}"
          flash[:notice] = "ERROR: request to update sam customer #{@task.sam_customer.id.to_s} did not complete as expected."
        end  
      else 
        logger.error("ERROR: no response from Web API call to update sam customer #{@task.sam_customer.id.to_s}.")
        flash[:notice] = ("ERROR: no response from Web API call to update sam customer #{@task.sam_customer.id.to_s}.")
      end
    elsif (params[:not_here] == "unmatched")
      flash[:notice] = "You cannot close this task until all schools are matched."
    else
      flash[:notice] = "Something about this task is not right."
    end    
    flash[:msg_type] = "info"
    redirect_to(user_tasks_path(:id => current_user.id))
  rescue Exception => e #not really needed unless I want to raise exceptions elsewhere that will be picked up by this rescue
    logger.info(e.to_s)
    flash[:notice] = "Error occurred while processing your request: #{e}.  Please take note of the task ID and notify an SAMC administrator" if flash[:notice].nil?
    redirect_to(edit_sc_licensing_activation_path(@task.id))
  end
  
  
  
  def sync_steps_status_for
    create = (params[:value] == "true")
    if (create)
      TaskParam.create(:task_id => params[:id], :name => "box", :value => params[:box])
    else
      TaskParam.destroy_all("task_id=#{params[:id]} and name='box' and value='#{params[:box]}'")
    end
    respond_to do |format|
      format.html { render(:text => false)}
      format.js { render(:text => false)}
    end
  end
  
  
  
  #####################
  # PROTECTED METHODS #
  #####################
  
  protected
  
  
  
  class ScLicensingActivationUpdateException < UpdateException
    UNKNOWN = 0
    INCONSISTENT_LICENSE_COUNTS = 1
    ALREADY_ACTIVATED = 2
    BLANK_REASON = 3
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, sam_customer, redirect)    
    end
  end
  
  def load_view_vars
    @crappy_modal_support = true
  end
  
  
	
end
