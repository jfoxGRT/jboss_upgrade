require 'entitlement_manager/defaultDriver'
require 'sam_customer_manager/defaultDriver'
require 'user_manager/defaultDriver'
require 'fastercsv'

class TasksController < ApplicationController
  
  include EntitlementManager
  include SamCustomerManager
  include UserManager
  
  layout 'default'
  
  before_filter :load_users, :only => [:assigned, :unassigned]
  before_filter :load_task, :only => [:edit, :show, :update, :assign, :unassign]
  before_filter :load_widget
  
  
  
  def index
    get_task_counts
    @task_packages, @number_of_tasks = Task.build_task_packages(current_user, nil, Task.ASSIGNED)
    @task_packages.sort!{|a,b| b[1][0].date_assigned <=> a[1][0].date_assigned}
    task_orgs = TaskOrg.find_task_org_info_for_assigned_tasks(current_user)
    @task_orgs_hash = TaskOrg.build_task_orgs_hash(task_orgs)
    # render(:layout => "new_layout_with_jeff_stuff")
    # redirect_to(user_tasks_path(:id => current_user.id))
  end
  
  def user
    @task_packages, @number_of_tasks = Task.build_task_packages(params[:id], nil, Task.ASSIGNED)
    @task_packages.sort!{|a,b| b[1][0].date_assigned <=> a[1][0].date_assigned}
    task_orgs = TaskOrg.find_task_org_info_for_assigned_tasks(current_user)
    @task_orgs_hash = TaskOrg.build_task_orgs_hash(task_orgs)
    puts "@action_name: #{@action_name}"
    puts "number of tasks: #{@number_of_tasks}"
    puts "task_packages[0] type: #{@task_packages[0].class}"
    puts "task_packages: #{@task_packages.to_yaml}"
  end
  
  
  
  def show
    @task_events = TaskEvent.find(:all, :conditions => ["task_id = ?", @task.id], :order => "created_at")
    @sam_customer = @task.sam_customer
    render(:layout => "new_layout_with_jeff_stuff")
  end
  
  def get_task_details
    @task = Task.find(params[:task_id])
    @task_events = TaskEvent.find(:all, :conditions => ["task_id = ?", params[:task_id]], :order => "created_at")
    @sam_customer = @task.sam_customer
	render(:partial => "get_task_details")
  end
  
  def assigned 
  end
  
  
  
  def unassigned    
  end
  
  
  
  def edit
    case (@task.task_type.code)
      when TaskType.PENDING_ENTITLEMENT_CODE then redirect_to(edit_pending_entitlement_path(@task.id))
      when TaskType.SC_LICENSING_ACTIVATION_CODE then redirect_to(edit_sc_licensing_activation_path(@task.id))
      when TaskType.LICENSE_COUNT_DISCREPANCY_CODE then redirect_to(edit_license_count_discrepancy_path(@task.id))
	  when TaskType.LICENSE_COUNT_INTEGRITY_PROBLEM_CODE then redirect_to(edit_license_count_integrity_problem_path(@task.id))
      when TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE then redirect_to(edit_pending_license_count_change_path(@task.id))
      when TaskType.SUPER_ADMIN_REQUEST_CODE then redirect_to(edit_super_admin_request_path(@task.id))
    end
  end
  
  
  
  def assign
    begin
      target_user_id = params[:target_user_id]
      target_user_id = current_user.id if target_user_id.nil?
      assign_task(@task, target_user_id)
      status = "success"
    rescue Exception => e
      logger.info(e.to_s)
      flash[:notice] = "Your request could not be processed at this time.  Please try again later." if flash[:notice].nil?
      status = "failure"
    end
    # respond_to do |format|
    #       format.html {render(:text => status)}
    #       format.js {render(:text => status)}
    #     end
    render(:text => status)    
  end
  
  
  
  def unassign
    puts "params: #{params.to_yaml}"
    (redirect_to(:action => :index) and return) if (params[:id].nil?)
    task = Task.find(params[:id])
    sam_customer = task.sam_customer
    begin
      Task.transaction do
        if (task.status != Task.ASSIGNED)
          flash[:notice] = "Unassignment Failed:  This task is not assigned to any user."
          raise
        end
        te = TaskEvent.create(:task => task, :source_user_id => current_user.id, :target_user_id => task.current_user.id, :action => TaskEvent.UNASSIGN)
        task.update_attributes(:status => Task.UNASSIGNED, :current_user => nil, :last_task_event => te)
      end
    rescue
      flash[:notice] = "That action could not be processed at this time.  Please try again later." if (flash[:notice].nil?)
    end
    if (params[:revocation].nil?)
      case (task.task_type.code)
        when TaskType.PENDING_ENTITLEMENT_CODE then redirect_to(unassigned_pending_entitlements_path)
        when TaskType.SUPER_ADMIN_REQUEST_CODE then redirect_to(unassigned_super_admin_requests_path)
       	when TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE then redirect_to(unassigned_pending_license_count_changes_path(:sam_customer_id => sam_customer.id))
       	when TaskType.SC_LICENSING_ACTIVATION_CODE then redirect_to(unassigned_sc_licensing_activations_path)
        else redirect_to(:action => :user, :id => current_user.id)
      end
    else
      case (task.task_type.code)
        when TaskType.PENDING_ENTITLEMENT_CODE then redirect_to(assigned_pending_entitlements_path)
        when TaskType.SUPER_ADMIN_REQUEST_CODE then redirect_to(assigned_super_admin_requests_path)
       	when TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE then redirect_to(assigned_pending_license_count_changes_path)
       	when TaskType.SC_LICENSING_ACTIVATION_CODE then redirect_to(assigned_sc_licensing_activations_path)
        else redirect_to(:action => :user, :id => current_user.id)
      end
    end
  end
  
  
  def search
  	#put whole array from search form into session
    #when generating csv, :task will not be included in the request
    if (params[:task])
      session[:task] = params[:task]
    end
  	
  	if (session[:task] and !session[:task].empty?) 
      session[:task].each_pair {|k,v| v.strip!}
    end
    
    if(session[:task][:task_type_id] == "4")
      @task_type="license_count_discrepancy"
    elsif(session[:task][:task_type_id] == "1")
      @task_type="pending_entitlement"
    elsif(session[:task][:task_type_id] == "2")
      @task_type="pending_license_count_change"
    elsif(session[:task][:task_type_id] == "5")
      @task_type="sc_licensing_activation"
    elsif(session[:task][:task_type_id] == "7")
      @task_type="super_admin_request"
    else
      @task_type="any"
    end

  	payload = params[:task]
  	@tasks = find_tasks(payload, FINDER_LIMIT)
    
    @pending_entitlement_task_type = TaskType.find_by_code(TaskType.PENDING_ENTITLEMENT_CODE)
    
    @num_rows_reported = @tasks.length #duplicate of @new_number_of_tasks here; re-using name for consistency across Finder view code
    @new_number_of_tasks = @tasks.length

    if(request.xhr?) #if an ajax request...
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end
  end
  
  def find_tasks(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['task_finder_web_services'] + "#{limit.to_s}")
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@tasks = []
	@errors = []
	errorsMap = parsed_json["errors"]
	if(errorsMap)
	  puts errorsMap
	  parsed_json["errors"].each do |err|
	    err_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(err))
	    err_row.each {|k,v|
		  @errors << v
	    }
	  end
	else		
		parsed_json["tasks"].each do |e|
			t = Task.new
			e.each {|k,v|
				t[k.to_sym] = v
			}
			
			@tasks << t
		end
	end
	@ret_tasks = @tasks
  end
  
  
  def update
  	@comment = nil
    puts "params: #{params.to_yaml}"
    @try_again = false
    @made_obsolete = false
    @task = Task.find(params[:id])
    @sam_customer = @task.sam_customer
    if (@task.status == Task.CLOSED)
      flash[:notice] = "Aborting task.  This task has already been closed by someone."
      flash[:msg_type] = "info"
      redirect_to(:action => :user, :id => current_user.id)
      return
    end
    if (@task.status == Task.OBSOLETE)
      flash[:notice] = "Aborting task.  This task (ID = #{@task.id}) has an invalid status.  Please note the task ID and contact an SAMC system administrator."
      redirect_to(:action => :user, :id => current_user.id)
      return
    end
    #(redirect_to(:action => :edit, :id => params[:id]) and return) 
    case (@task.alert.code)
      when Alert.UNASSIGNED_ENTITLEMENT_CODE then update_uo_task(@task)
      when Alert.SC_LICENSING_ACTIVATION_CODE then update_scla_task(@task)
      when Alert.NO_ACCOUNT_ADMINISTRATOR_CODE then update_naa_task(@task)
      when Alert.LICENSE_COUNT_DISCREPANCY_CODE then update_lcd_task(@task)
      when Alert.LICENSE_COUNT_INTEGRITY_CODE then update_lcip_task(@task)
      when Alert.SUPER_ADMIN_REQUEST_CODE then update_nsa_task(@task)
	    when Alert.PENDING_LICENSE_COUNT_CHANGE_CODE then update_plcc_task(@task)
      else
        begin
          flash[:notice] = "This task has an invalid notification code.  Please note the task ID and alert a system administrator."
          @try_again = true
        end
    end
    return if @try_again == true
    (redirect_to(user_tasks_path(:id => current_user.id)) and return) if @made_obsolete == true
    te = TaskEvent.create(:task => @task, :source_user => current_user, :target_user_id => @task.current_user, :action => TaskEvent.CLOSE, :comment => @comment)
    @task.update_attributes(:status => Task.CLOSED, :current_user_id => nil, :last_task_event => te)
	   redirect_to(user_tasks_path(:id => current_user.id))
  end
  
  
  def export_tasks_to_csv
    logger.info "EXPORTING Tasks CSV, Params: #{params.to_yaml}"
    
    tasks_search_result = Task.search(session[:task])
    # server-side CSV always uses default sort, not necessarily current sort in finder display
    
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["ID", "Type", "Status", "Comment", "Created", "Closed", "Closed By", "TMS Entitlement ID", PRODUCT_TERM, "License Count", "Order #", "Invoice #", SAM_CUSTOMER_TERM]
      tasks_search_result.each do |task|
        if(task.created_at)
          created_at_date = task.created_at.strftime(DATE_FORM)
        else
          created_at_date = nil
        end
        if(task["task_closed_at"])
          closed_at_date = task["task_closed_at"]
        else
          closed_at_date = nil
        end
        # data row
        if(task.task_type == TaskType.find_by_code(TaskType.PENDING_ENTITLEMENT_CODE))
          csv_row << [task.id, task.task_type_description, translateTaskStatusCode(task.status), task["comment"], created_at_date, closed_at_date, "#{task['closed_by_first_name']} #{task['closed_by_last_name']}".strip, task["tms_entitlementid"], task["product_description"], task.license_count, task["order_num"], task["invoice_num"], (task["sam_customer_name"] ? task["sam_customer_name"].strip : nil)]
        else
          csv_row << [task.id, task.task_type_description, translateTaskStatusCode(task.status), task["comment"], created_at_date, closed_at_date, "#{task['closed_by_first_name']} #{task['closed_by_last_name']}".strip, nil, nil, nil, nil, nil, task["sam_customer_name"].strip]
        end
      end
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => TASK_FINDER_RESULTS_FILENAME)
  end
    
  #################
  # AJAX ROUTINES #
  #################
  
  
  def reopen
    @task = Task.find(params[:id])
    @error_code = 0
    puts "params: #{params.to_yaml}"
    @new_number_of_tasks = params[:number_of_tasks].to_i - 1
    begin
      Task.transaction do
        if (@task.status == Task.CLOSED)
          # insert task_event for reopen
          reopen_task_event = TaskEvent.create(:task => @task, :source_user_id => params[:source_user_id], :action => TaskEvent.REOPEN)
          # set task status to open and reset last_task_event to most recently added task event
          @task.update_attributes(:status => Task.UNASSIGNED, :last_task_event => reopen_task_event)
          # if this is a pending_entitlement task..
          if (@task.task_type == TaskType.pending_entitlement)
            # get the samc customer of the task
            sam_customer = @task.sam_customer
            # get the entitlement
            entitlement = @task.alert_instances[0].entitlement
            # get the product of the task's entitlement
            product = entitlement.product
            # if the product is a sam server product (has licenses)..
            if (product.sam_server_product && (!sam_customer.nil?))
              # get the subcommunity
              subcommunity = product.subcommunity
              if (subcommunity.nil?)
                @error_code = 2
                raise
              end
              # get the seat pool
              seat_pool = SeatPool.obtain_seat_pool(sam_customer, subcommunity, nil)
              # if there aren't enough seats available to recoup..
              if (seat_pool.seat_count < entitlement.license_count)
                @error_code = 3
                raise
              end
              # recoup the seats
              seat_pool.seat_count -= entitlement.license_count
              seat_pool.save
              # clear the sam_customer for the entitlement and the task
              entitlement.update_attribute(:sam_customer, nil)
              @task.update_attribute(:sam_customer, nil)
              # delete any known_destination related to the entitlement
              EntitlementKnownDestination.delete_by_entitlement(entitlement)
            end
          end
        else
          @error_code = 1
        end
      end
    rescue
      @error_code = -1 if @error_code == 0
    end
    puts "error code is #{@error_code}"
  end
  
  
  
  def add_comment_for
  	puts "params: #{params.to_yaml}"
  	task_event = TaskEvent.find(:first, :conditions => ["task_id = ? and target_user_id = ? and action = 'a'", params[:id], current_user.id], :order => "created_at desc")
  	task_event.comment = params[:comments]
  	task_event.save
  	redirect_to(edit_task_path(params[:id]))
  end
  
  
  def show_params
    task = Task.find(params[:id])
    render(:partial => "/tasks/show_params", :object => task.task_params)
  end
 
 
  
  #####################
  # PROTECTED METHODS #
  #####################
  
  protected
  
  
  
  def assign_task(task, target_user_id)
    raise AssignException.new(task, flash, "Missing required parameter for request (either task or target_user_id is null)", AssignException::INVALID_HTTP_REQUEST, target_user_id) if (task.nil? || target_user_id.nil?)
    raise AssignException.new(task, flash, "Task ID #{task.id} is not available for assignment.", AssignException::TASK_ALREADY_ASSIGNED, target_user_id) if (task.status != Task.UNASSIGNED)
    Task.transaction do
      te = TaskEvent.create(:task => task, :source_user_id => current_user.id, :target_user_id => target_user_id, :action => TaskEvent.ASSIGN)
      task.update_attributes(:status => Task.ASSIGNED, :current_user_id => target_user_id, :last_task_event => te)
    end
  end
  
  
  
  def validate_for_updating(task)
    if (task.status == Task.CLOSED)
      flash[:notice] = "Aborting task.  This task has already been closed by someone."
      flash[:msg_type] = "info"
      return false
    end
    if (task.status == Task.OBSOLETE)
      flash[:notice] = "Aborting task.  This task (ID = #{task.id}) has an invalid status.  Please note the task ID and contact a system administrator."
      return false
    end
    return true
  end
  
  
  
  def close_task(task, sam_customer = nil, comment = nil)
    raise UpdateException.new(task, flash, "The task has already been closed", UpdateException::TASK_ALREADY_CLOSED) if task.status == Task.CLOSED
    raise UpdateException.new(task, flash, "This task has become obsolete.  Please notify an SAMC administrator", UpdateException::TASK_OBSOLETE) if task.status == Task.OBSOLETE
    Task.transaction do
      if(!sam_customer.nil?)
        te = TaskEvent.create(:task => task, :source_user => current_user, :target_user_id => task.current_user, :action => TaskEvent.CLOSE, :sam_customer => sam_customer, :comment => comment)
        task.update_attributes(:status => Task.CLOSED, :current_user_id => nil, :last_task_event => te, :sam_customer => sam_customer)
      else
        te = TaskEvent.create(:task => task, :source_user => current_user, :target_user_id => task.current_user, :action => TaskEvent.CLOSE, :comment => comment)
        task.update_attributes(:status => Task.CLOSED, :current_user_id => nil, :last_task_event => te)
      end
    end
  end
  
  
  
  class TaskException < Exception
    UNKNOWN = 0
    attr_reader :task, :msg, :exception_code, :task_obsolete, :redirect
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(msg)
      flash[:notice] = msg if msg
      @task, @msg, @task_obsolete, @exception_code, @redirect = task, msg, task_obsolete, exception_code, redirect
      if(@task && @task_obsolete)
        @task.make_task_obsolete(sam_customer, msg)
      end
    end
    
    def to_s
      super + " #{self.class} - #{msg} : task id = " + ((@task.nil?) ? "-unknown-" : "#{@task.id}") + "; exception_code = #{@exception_code}; task_obsolete = #{@task_obsolete}; redirect = #{@redirect}"
    end
    
  end
  
  
  
  class EditException < TaskException 
    UNKNOWN = 0
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, redirect) 
    end    
  end
  
  
  
  class UpdateException < TaskException
    UNKNOWN = 0
    TASK_ALREADY_CLOSED = 1
    TASK_OBSOLETE = 2
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, redirect) 
    end
  end



  class AssignException < TaskException
    UNKNOWN = 0
    TASK_ALREADY_ASSIGNED = 1
    INVALID_HTTP_REQUEST = 2
    attr_reader :target_user_id
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, target_user_id = nil, task_obsolete = false, sam_customer = nil, redirect = nil)
      @exception_code, @target_user_id = exception_code, target_user_id
      super(task, flash, msg, exception_code, task_obsolete, redirect)
    end
    
    def to_s
      super + " : target_user_id = #{@target_user_id}"
    end
  end  
  
  
  ###################
  # PRIVATE METHODS #
  ###################
  
  private
  
  def load_widget
    @widget_list << Widget.new("show_params", "Task Parameters", nil, 300, 300)
    @crappy_modal_support = true
  end
  
  
  def load_task
    if params[:id]
      @task = Task.find(params[:id])
    else
      @task = nil
    end
  end
  
  
  
  def load_users
      @user_list = Task.find_user_list_with_task_counts if (current_user.hasPermission?(Permission.assign_tasks) && current_user.hasPermission?(Permission.edit))
  end  
  
  def translateTaskStatusCode(task_status_code)
    case (task_status_code)
      when Task.UNASSIGNED then "Unassigned"
      when Task.ASSIGNED then "Assigned"
      when Task.CLOSED then "Closed"
    end
  end
  
end