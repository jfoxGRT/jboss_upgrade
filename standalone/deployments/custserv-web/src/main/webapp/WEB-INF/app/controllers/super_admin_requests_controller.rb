require 'java'
#import 'java.lang.Integer'
#import 'java.util.HashMap'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
require 'user_manager/defaultDriver'

class SuperAdminRequestsController < TasksController
  
  before_filter :load_view_vars
  
  layout "default"
  
  def assigned
    task_type = TaskType.find_by_code(TaskType.SUPER_ADMIN_REQUEST_CODE)
    (redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
    @tasks = Task.find(:all, :select => "t.*, sp.name as state_name, sc.name as sam_customer_name, ssa.admin_permission_requested, u.id as target_user_id, u.first_name, u.last_name", 
                        :joins => "t inner join state_province sp on t.state_province_id = sp.id 
                                   inner join sam_customer sc on t.sam_customer_id = sc.id
                                   inner join users u on t.current_user_id = u.id
                                   left join task_params tp on (tp.task_id = t.id and tp.name = 'serverId')
                                   left join sam_server ss on tp.value = ss.id
                                   left join sam_server_address ssa on ssa.sam_server_id = ss.id", 
                       :conditions => ["t.task_type_id = ? and t.status = 'a'", task_type.id])
  end
  
  
  
  def unassigned
    task_type = TaskType.find_by_code(TaskType.SUPER_ADMIN_REQUEST_CODE)
    if (!params[:scholastic_index].nil?)
      (redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
      params[:sort] ||= "priority_desc"
      puts "params[:sort] = #{params[:sort].to_yaml}"
      @sort_order = params[:sort]
  	  conditions_clause = "t.task_type_id = ? and t.status = 'u' and si.id = ?"
  	  conditions_fillins = [task_type.id, params[:scholastic_index]]
  	  if (!params[:sam_customer_id].nil?)
  		  conditions_clause << " and t.sam_customer_id = ?"
  		  conditions_fillins << params[:sam_customer_id]
  	  end
      case (@sort_order)
        when "id" then orders_clause = "t.id"
        when "id_desc" then orders_clause = "t.id desc"
        when "priority" then orders_clause = "t.priority"
        when "priority_desc" then orders_clause = "t.priority desc"
        when "state" then orders_clause = "sp.name"
        when "state_desc" then orders_clause = "sp.name desc"
        when "cust" then orders_clause = "sc.name"
        when "cust_desc" then orders_clause = "sc.name desc"
        when "date" then orders_clause = "t.created_at"
        when "date_desc" then orders_clause = "t.created_at desc"
        when "reason" then orders_clause = "ssa.admin_permission_requested desc"
        when "reason_desc" then orders_clause = "ssa.admin_permission_requested"
        else orders_clause = "t.priority desc"
      end
      @tasks = Task.find(:all, :select => "t.*, sp.name as state_name, sc.name as sam_customer_name, ssa.admin_permission_requested", 
                          :joins => "t inner join state_province sp on t.state_province_id = sp.id
                                     inner join sam_customer sc on t.sam_customer_id = sc.id
                                     inner join scholastic_index si on sc.scholastic_index_id = si.id
                                     left join task_params tp on (tp.task_id = t.id and tp.name = 'serverId')
                                     left join sam_server ss on tp.value = ss.id
                                     left join sam_server_address ssa on ssa.sam_server_id = ss.id", 
                         :conditions => [conditions_clause, conditions_fillins].flatten, :order => orders_clause)
      p "@tasks: #{@tasks.to_yaml}"
    else
      @task_groups = Task.find(:all, :select => "si.id, si.description, count(t.id) as number_of_tasks",
          :joins => "t inner join sam_customer sc on t.sam_customer_id = sc.id
                    inner join scholastic_index si on sc.scholastic_index_id = si.id",
          :conditions => ["t.task_type_id = ? and t.status not in ('c','z')", task_type.id], :group => "si.id")
    end
  end
  
  
  
  def edit
    if (params[:user])
      @user = User.new(params[:user])
    else
      @user = User.new
    end
    @sam_customer = @task.sam_customer
    @org_details = Org.find_summary_details(@sam_customer.root_org.id)
    @sam_server = SamServer.find(@task.task_params.detect{|tp| tp.name == "serverId"}.value.to_i)
    raise SuperAdminRequestEditException.new(@task, flash, "There is no SAM Server associated with this task (ID = #{@task.id}).  Please note the task ID and alert a system administrator.",
                      SuperAdminRequestEditException::NO_SAM_SERVER, false, @task.sam_customer) if(@sam_server.nil?)
    @salutations = Salutation.find(:all, :order => "display_order").collect {|s| [s.description, s.id]}
    @job_titles = JobTitle.find(:all, :order => "display_order").collect {|jt| [jt.description, jt.id]}
    sam_server_address = @sam_server.sam_server_address
    raise SuperAdminRequestEditException.new(@task, flash, "The SAM Server associated with this task (ID = #{@task.id}) doesn't have any address info.  Please note the task ID and alert a system administrator.",
                      SuperAdminRequestEditException::NO_SAM_SERVER_ADDRESS, false, @task.sam_customer) if(sam_server_address.nil?)
    @sam_server_address = (sam_server_address.admin_permission_requested) ? sam_server_address : nil
    if (@sam_server_address)
      @user.first_name = @sam_server_address.first_name
      @user.last_name = @sam_server_address.last_name
      @user.email = @sam_server_address.email_address
      @user.job_title = @sam_server_address.job_title
      @user.salutation = @sam_server_address.salutation
      @user.phone = @sam_server_address.phone_number
    end
  rescue Exception => e
    logger.info("TASK ERROR: #{e}")
    flash[:notice] = "There was an unexpected error while processing your request.  Please take note of the task ID inform a SAMC administrator." if flash[:notice].nil?
    redirect_to(user_tasks_path(:id => current_user.id))
  end
  
  
  
  def update
    
    values = (params[:user].collect {|p| p[1]})
    values.each do |p|
      raise SuperAdminRequestUpdateException.new(@task, flash, "All fields are required", 
                    SuperAdminRequestUpdateException::ALL_FIELDS_REQUIRED, false, @task.sam_customer) if (p.strip.empty?)
    end
    not_applicable_salutation = Salutation.find_by_code("NA")
    if (not_applicable_salutation.nil?)
      flash[:notice] = "ERROR: Internal required record is not available.&nbsp;&nbsp;Please contact an SAMC administrator"
      redirect_to(new_user_path)
      return
    end
    user_service = SC.getBean("userService")
    result = user_service.createOriginalCustomerUser(params[:user][:email], not_applicable_salutation.id,
                      params[:user][:first_name], params[:user][:last_name], params[:user][:job_title_id].to_i,
                      params[:user][:phone], @task.sam_customer.id, [].to_java(:Integer), nil)    
    if result.success
      close_task(@task)
      flash[:notice] = "New Super Admin Added for " + @task.sam_customer.name
      flash[:msg_type] = "info"
      redirect_to(user_tasks_path(:id => current_user.id))
    else
      puts "result: #{result.to_yaml}"
      case result.errorCode
        when 6 then raise SuperAdminRequestUpdateException.new(@task, flash, "Aborting task.  A Super Admin already exists for this account, to which an email request has been forwarded on behalf of this user.",
                            SuperAdminRequestUpdateException::SUPER_ADMIN_ALREADY_EXISTS, true, @task.sam_customer, user_tasks_path(:id => current_user.id)) 
        when 0 then raise SuperAdminRequestUpdateException.new(@task, flash, "That email address is already reserved.  Please select a different email address.", 
                            SuperAdminRequestUpdateException::EMAIL_ALREADY_RESERVED, false, @task.sam_customer)
        else raise SuperAdminRequestUpdateException.new(@task, flash, "Your request could not be completed successfully at this time.  Please notify an SAMC administrator.",
                            SuperAdminRequestUpdateException::UNKNOWN, false, @task.sam_customer)
      end
    end
  rescue Exception => e
    logger.info("Experienced error during Super Admin Request update: #{e.to_s}")
    if flash[:notice].nil?
      flash[:notice] = "Error occurred while adding new Super Admin."
      flash[:notice] += "(exception code = #{e.exception_code})" if e.instance_of?(TaskException)
      flash[:notice] += "&nbsp;&nbsp;Please contact an SAMC Administrator"
    end
    redirect_to((!e.instance_of?(TaskException) || e.redirect.nil?) ? edit_super_admin_request_path(@task.id) : e.redirect)
  end
  
  
  #####################
  # PROTECTED METHODS #
  #####################
  
  protected
  
  
  
  class SuperAdminRequestEditException < EditException
    UNKNOWN = 0
    NO_SAM_SERVER = 1
    NO_SAM_SERVER_ADDRESS = 2
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, sam_customer, redirect)    
    end
  end
  
  
  
  class SuperAdminRequestUpdateException < UpdateException
    UNKNOWN = 0
    SUPER_ADMIN_ALREADY_EXISTS = 1
    EMAIL_ALREADY_RESERVED = 2
    ALL_FIELDS_REQUIRED = 3
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, sam_customer, redirect)
    end
  end
  
  def load_view_vars
    @crappy_modal_support = true
  end
  
  
  
end
