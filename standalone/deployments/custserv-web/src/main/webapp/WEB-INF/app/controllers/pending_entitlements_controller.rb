require 'entitlement_manager/defaultDriver'

class PendingEntitlementsController < TasksController
  
  include EntitlementManager
  
  before_filter :load_view_vars
  
  #layout "new_layout_for_tasks"
  layout "default"

  def assigned
    params[:sort] ||= "task_date_desc"
    puts "params[:sort] = #{params[:sort].to_yaml}"
    @sort_order = params[:sort]
    @task_packages, @number_of_tasks = Task.build_task_packages(nil, TaskType.PENDING_ENTITLEMENT_CODE, Task.ASSIGNED, 9999, params[:sort])
    task_orgs = TaskOrg.find_task_org_info_for_open_tasks
    @task_orgs_hash = TaskOrg.build_task_orgs_hash(task_orgs)
  end
  
  
  
  def unassigned
    puts "params: #{params.to_yaml}"
    params[:sort] ||= "task_date_desc"
    puts "params[:sort] = #{params[:sort].to_yaml}"
    @sort_order = params[:sort]
    @paginated_packages = get_pending_entitlement_tasks(Task.UNASSIGNED, params[:sort]).paginate(:page => params[:page], :per_page => 50)
    p "size of pp: #{@paginated_packages.length}"
    task_orgs = get_task_org_info(@paginated_packages)
    @task_orgs_hash = TaskOrg.build_task_orgs_hash(task_orgs)
    logger.info "@number_of_tasks: #{@number_of_tasks}"
  end
  
  
  
  def edit
    @task_events = TaskEvent.find(:all, :select => "te.*, su.last_name as source_user_last_name, tu.last_name as target_user_last_name", 
            :joins => "te left join users su on te.source_user_id = su.id
                 left join users tu on te.target_user_id = tu.id", 
            :conditions => ["te.task_id = ?", @task.id], :order => "te.created_at")
    @assigned_task_event = TaskEvent.find(:first, :conditions => ["task_id = ? and target_user_id = ? and action = 'a'", params[:id], current_user.id], :order => "created_at desc")
    @number_of_events = @task_events.length
    @assigning_user = @task_events[@number_of_events - 1].source_user
    @task_info = Task.find_entitlement_org_info(@task)
    @number_of_entitlements = Entitlement.count(:conditions => ["order_num = ? and invoice_num = ?", @task_info[0].order_num, @task_info[0].invoice_num])
    @task_org_info = TaskOrg.find_task_org_info(@task)
  end
  
  
  
  def update
    raise PendingEntitlementUpdateException.new(@task, flash, "A UCN must be selected",
                    PendingEntitlementUpdateException::UCN_REQUIRED) if (params[:ucn].nil?)
    # if the user closed the task without assigning a UCN..
    if(params[:ucn].empty?)
      close_task(@task, nil, "Closing Pending Entitlement task without assignment")
      flash[:notice] = "Successfully closed task ID #{@task.id} without assignment"
      flash[:msg_type] = "info"
      redirect_to(unassigned_pending_entitlements_path)
      return
    end
    ucn = params[:ucn].to_i
    customer = Customer.find_by_ucn(ucn)
    # verify that the ucn exists in sam connect
    raise PendingEntitlementUpdateException.new(@task, flash, "The submitted UCN is no longer recognized by SAM Connect.  Please notify a system administrator.",
                    PendingEntitlementUpdateException::UNRECOGNIZED_UCN) if (customer.nil?)
    # verify that the org is open; otherwise, fail the request
    raise PendingEntitlementUpdateException.new(@task, flash, "The submitted UCN is now closed and not available for entitlement assignment.  Please choose a different UCN.",
                    PendingEntitlementUpdateException::CLOSED_UCN) if (customer.closed?)
    org = customer.org
    entitlement = @task.alert_instances[0].entitlement
    add_known_destination = false
    if (params[:known_destination] == "yes")
      if(ekd = EntitlementKnownDestination.find_by_orgs(entitlement.billed_to_org, entitlement.shipped_to_org))
        raise PendingEntitlementUpdateException.new(@task, flash, "That combination of BILL-TO and SHIP-TO has already been reserved for #{ekd.sam_customer.name}.  Please" +
                          " deselect the checkbox in Step 2 of the Task Resolution pane.",
                          PendingEntitlementUpdateException::KNOWN_DESTINATION_RESERVED) if (ekd.sam_customer.root_org != org)
      end
      add_known_destination = true
    end
    # invoke the entitlement manager to finish the processing
    entitlementManager = EntitlementManagerPortType.new( ENTITLEMENT_MANAGER_URL )
    param = UpdateRootOrg.new
    param.entitlementId = entitlement.id
    param.orgId = org.id
    param.addKnownDestination = add_known_destination
    result = entitlementManager.updateRootOrg( param ).out
    puts "result: #{result.to_yaml}"
    raise PendingEntitlementUpdateException.new(@task, flash, result.__xmlele[0][1],
                  PendingEntitlementUpdateException::UNKNOWN) if ((result.__xmlele) && result.__xmlele[1][1] == "false")
    sam_customer = org.sam_customer
    raise PendingEntitlementUpdateException.new(@task, flash, "SAM Customer could not be set for closing task ID #{@task.id}.  Please notify a system administrator.",
                  PendingEntitlementUpdateException::UNSUCCESSFUL_SAM_CUSTOMER_ASSIGNMENT) if sam_customer.nil?
    close_task(@task, sam_customer)
    flash[:notice] = "Successfully closed task ID #{@task.id} by assigning entitlement to #{sam_customer.name}"
    flash[:msg_type] = "info"
    if (current_user.hasPermission?(Permission.assign_tasks))
    		redirect_to(user_tasks_path(:id => current_user.id))
    else
    		redirect_to(unassigned_pending_entitlements_path)
    end
  rescue Exception => e
    logger.info(e.to_s)
    flash[:notice] = "Error occurred while assigning entitlement to UCN.  Please note the task ID and inform a SAMC administrator." if flash[:notice].nil?
    redirect_to(edit_pending_entitlement_path(@task.id))
  end
  
  
  
  #################
  # AJAX ROUTINES #
  #################
  
  
  
  def view_all_unassigned
    @alert = Alert.find_by_code(Alert.UNASSIGNED_ENTITLEMENT_CODE)
    @task_packages, @number_of_tasks = Task.build_task_packages(nil, Alert.UNASSIGNED_ENTITLEMENT_CODE, Task.UNASSIGNED, 5000)
    task_orgs = TaskOrg.find_task_org_info_for_open_tasks
    @task_orgs_hash = TaskOrg.build_task_orgs_hash(task_orgs)
    puts "@task_packages: #{@task_packages.to_yaml}"
    render(:partial => "unassigned_task_info_table", :locals => {:alert_id => @alert.id, :task_orgs_hash => @task_orgs_hash, :entitlement_counts_hash => @entitlement_counts_hash})
  end
  
  
  
  #####################
  # PROTECTED METHODS #
  #####################
  
  protected
  
  
  
  
  class PendingEntitlementUpdateException < UpdateException
    UNKNOWN = 0
    KNOWN_DESTINATION_RESERVED = 1
    UNRECOGNIZED_UCN = 2
    CLOSED_UCN = 3
    UNSUCCESSFUL_SAM_CUSTOMER_ASSIGNMENT = 4
    UCN_REQUIRED = 5
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, sam_customer, redirect)    
    end
  end
  
  
  
  
  private
  
  def load_view_vars
    @crappy_modal_support = true
  end
  
  
  def build_entitlement_counts_hash(entitlement_counts_array)
    entitlement_counts_hash = {}
    entitlement_counts_array.each do |ec|
      hash_key = "#{ec.order_num}_#{ec.invoice_num}"
      entitlement_counts_hash[hash_key] = ec
    end
    return entitlement_counts_hash
  end
  
  def get_pending_entitlement_tasks(status, sort_order = "task_date_desc", user_id = nil)
    alert_type = Alert.find_by_code(Alert.UNASSIGNED_ENTITLEMENT_CODE)
  	task_type = TaskType.find_by_code(TaskType.UNASSIGNED_ENTITLEMENT_CODE)
     mailing_address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
  	select_clause = "t.*, ai.id as alert_instance_id,
                     e.id as entitlement_id,
                     e.tms_entitlementid as tms_entitlement_id,
                     e.order_num,
                     e.invoice_num,
                     bt_org.id as bt_org_id,
                     bt_customer.ucn as bt_ucn,
                     bt_org.name as bt_org_name,
                     bt_ca.address_line_1 as bt_address_line_1,
                     bt_ca.address_line_2 as bt_address_line_2,
                     bt_ca.address_line_3 as bt_address_line_3,
                     ifnull(bt_sp.code,'') as bt_state_code,
                     ifnull(bt_ca.city_name,'') as bt_city_name,
                     ifnull(bt_ca.county_code,'') as bt_county_code,
                     ifnull(bt_ca.zip_code,'') as bt_zip_code,
                     st_org.id as st_org_id,
                     st_customer.ucn as st_ucn,
                     st_org.name as st_org_name,
                     st_ca.address_line_1 as st_address_line_1,
                     st_ca.address_line_2 as st_address_line_2,
                     st_ca.address_line_3 as st_address_line_3,
                     ifnull(st_sp.code,'') as st_state_code,
                     ifnull(st_ca.city_name,'') as st_city_name,
                     ifnull(st_ca.county_code,'') as st_county_code,
                     ifnull(st_ca.zip_code,'') as st_zip_code,
                     p.description as product_name,
                     e.license_count,
                     tp.value as reason_unassigned,
                     e.ordered,
                     e.created_at as entitlement_created_at"
     joins_clause = "t inner join alert_instance ai on ai.task_id = t.id
                    inner join alert a on ai.alert_id = a.id
                    inner join entitlement e on ai.entitlement_id = e.id
                    inner join product p on e.product_id = p.id
                    inner join org bt_org on e.bill_to_org_id = bt_org.id
                    inner join customer bt_customer on bt_org.customer_id = bt_customer.id
                    inner join customer_address bt_ca on (bt_ca.customer_id = bt_customer.id and bt_ca.address_type_id = #{mailing_address_type.id})
                    left join state_province bt_sp on bt_ca.state_province_id = bt_sp.id
                    inner join org st_org on e.ship_to_org_id = st_org.id
                    inner join customer st_customer on st_org.customer_id = st_customer.id
                    inner join customer_address st_ca on (st_ca.customer_id = st_customer.id and st_ca.address_type_id = #{mailing_address_type.id})
                    left join state_province st_sp on st_ca.state_province_id = st_sp.id
                    left join task_params tp on (tp.task_id = t.id and tp.name = 'exceptionType')"
     conditions_clause_str = "a.id = ? and t.task_type_id = ?"
     conditions_clause_fillins = [alert_type.id, task_type.id]
	if (status == Task.ASSIGNED)
		if (user_id)
	   		joins_clause += " inner join task_events te on t.last_task_event_id = te.id inner join users u on te.source_user_id = u.id"
	   		select_clause += ", u.last_name as source_user_last_name, u.first_name as source_user_first_name, te.created_at as date_assigned"
	   		conditions_clause_str += " and t.current_user_id = ?"
	   		conditions_clause_fillins << user_id
	 	else
	   		joins_clause += " inner join users u on t.current_user_id = u.id"
	   		select_clause += ", u.id as target_user_id, u.last_name as assigned_user_last_name, u.first_name as assigned_user_first_name"
	   		conditions_clause_str += " and t.current_user_id is not null"
	 	end
	else
      	conditions_clause_str += " and t.status = ?"
      	conditions_clause_fillins << status
    	end
    case(sort_order)
      	when "product" then orders_clause = "product_name"
      	when "product_desc" then orders_clause = "product_name desc"
      	when "priority" then orders_clause = "t.priority"
     	when "priority_desc" then orders_clause = "t.priority desc"
     	when "task_date" then orders_clause = "t.created_at"
     	else orders_clause = "t.created_at desc"
    end
    conditions_clause = [conditions_clause_str, conditions_clause_fillins].flatten
    Task.find(:all, :select => select_clause, :joins => joins_clause, :conditions => conditions_clause, :order => orders_clause)
  end
  
  def get_task_org_info(task_packages)
  	id_list = ""
  	(task_packages.collect{|tp| tp.id}).each{|tp| id_list << "#{tp},"}
  	id_list.chop!  	
    address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    TaskOrg.find(:all, :select => "distinct t.id, o.name, ca.city_name, sp.code, ca.zip_code, ca.county_code, c.ucn, cg.description as group_description,
                                   ct.description as type_description, sc.id as sam_customer_id, sc.registration_date, sc.sc_licensing_activated,
                                   eot.description as entitlement_org_type_description", 
    :joins =>  "inner join tasks t on task_orgs.task_id = t.id 
                inner join org o on task_orgs.org_id = o.id
                inner join customer c on o.customer_id = c.id
                inner join customer_address ca on ca.customer_id = c.id
                inner join customer_group cg on c.customer_group_id = cg.id
                inner join customer_type ct on c.customer_type_id = ct.id
                inner join state_province sp on ca.state_province_id = sp.id
                left join entitlement_org_type eot on task_orgs.entitlement_org_type_id = eot.id
                left join sam_customer sc on sc.root_org_id = o.id", :conditions => ["t.id in (#{id_list}) and ca.address_type_id = ?", address_type.id],
                :order => "t.id")
  end
  
end