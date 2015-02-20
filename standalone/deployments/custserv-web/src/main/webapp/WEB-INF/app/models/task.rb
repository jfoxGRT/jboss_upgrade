class Task < ActiveRecord::Base
  belongs_to :sam_customer
  belongs_to :state_province
  has_many :task_events
  has_many :alert_instances
  has_many :task_params
  has_many :task_orgs
  belongs_to :task_type
  belongs_to :last_task_event, :class_name => "TaskEvent", :foreign_key => "last_task_event_id"
  belongs_to :current_user, :class_name => "User", :foreign_key => "current_user_id"
  
  @@UNASSIGNED = 'u'
  @@ASSIGNED = 'a'
  @@CLOSED = 'c'
  @@OBSOLETE = 'z'
  
	@@CODE_PENDING_ENTITLEMENT = "UE"
	@@CODE_PENDING_LICENSE_COUNT_CHANGE = "PLCC"
	@@CODE_LICENSE_COUNT_DISCREPANCY = "LCD"
	@@CODE_LICENSE_COUNT_INTEGRITY_PROBLEM = "LCIP"
	@@CODE_SUPER_ADMIN_REQUEST = "NSA"
	@@CODE_SC_LICENSING_ACTIVATION = "SCLA"
  
  @@MAX_TASKS_DISPLAYED = 50
  
  def self.UNASSIGNED
    @@UNASSIGNED
  end
  
  def self.ASSIGNED
    @@ASSIGNED
  end
  
  def self.CLOSED
    @@CLOSED
  end
  
  def self.OBSOLETE
    @@OBSOLETE
  end
  
  def self.MAX_TASKS_DISPLAYED
    @@MAX_TASKS_DISPLAYED
  end
  
  @@STATUSES = [
    ["Unassigned", Task.UNASSIGNED],
    ["Assigned", Task.ASSIGNED],
    ["Closed", Task.CLOSED]
  ]
  
  def self.STATUSES
    @@STATUSES
  end
  
  def self.find_for_sam_customer(sam_customer)
	Task.find(:all, :select => "tt.code, tt.description, count(tt.id) as task_count", :joins => "t inner join task_types tt on t.task_type_id = tt.id", 
				:conditions => ["t.sam_customer_id = ? and t.status not in (?, ?)", sam_customer, @@CLOSED, @@OBSOLETE], :group => "tt.id")
  end
  
  def make_task_obsolete(sam_customer = nil, comment = nil)
    if (!sam_customer.nil?)
      te = TaskEvent.create(:task => self, :source_user => current_user, :target_user_id => self.current_user, :action => TaskEvent.MAKE_OBSOLETE, :comment => comment)
      self.update_attributes(:status => Task.OBSOLETE, :current_user_id => nil, :last_task_event => te, :sam_customer => sam_customer)
    else
      te = TaskEvent.create(:task => self, :source_user => current_user, :target_user_id => self.current_user, :action => TaskEvent.MAKE_OBSOLETE, :comment => comment)
      self.update_attributes(:status => Task.OBSOLETE, :current_user_id => nil, :last_task_event => te)
    end
  end
  
  
  # get one array of open LCD tasks for any SamServer in the given collection. subcommunity may be nil.
  def self.find_open_lcd_tasks_for_servers(sam_servers, subcommunity)
    lcd_tasks = Array.new
    
    sam_servers.each do |sam_server|
      lcd_tasks << find_open_lcd_tasks(sam_server, subcommunity)
    end
    
    lcd_tasks.flatten!
  end
  
  
  # subcommunity may be nil
  def self.find_open_lcd_tasks(sam_server, subcommunity)
    task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_DISCREPANCY_CODE)
    joins_clause = "t inner join task_params tp1 on (tp1.task_id = t.id and tp1.name = 'samServerId' and tp1.value = #{sam_server.id}) "
    joins_clause += "inner join task_params tp2 on (tp2.task_id = t.id and tp2.name = 'subcommunityId' and tp2.value = #{subcommunity.id})" if subcommunity
    Task.find(:all, :select => "t.*", :joins => joins_clause, :conditions => ["t.task_type_id = ? and t.status not in (?, ?)", task_type.id, @@CLOSED, @@OBSOLETE])
  end
  
  # subcommunity may be nil
  def self.find_open_lcip_tasks(sam_customer, subcommunity)
    task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_INTEGRITY_PROBLEM_CODE)
    joins_clause = ""
    joins_clause += "inner join task_params tp2 on (tp2.task_id = tasks.id and tp2.name = 'subcommunityId' and tp2.value = #{subcommunity.id})" if subcommunity
    Task.find(:all, :select => "tasks.*", :joins => joins_clause, :conditions => ["tasks.task_type_id = ? and tasks.sam_customer_id = ? and tasks.status not in (?, ?)", task_type.id, sam_customer.id, @@CLOSED, @@OBSOLETE])
  end
  
  
  # get one array of open PLCC tasks for any SamServer in the given collection. sam_servers collection is required -- for all PLCC tasks at a given SamCustomer,
  # use find_open_plcc_tasks(). subcommunity may be nil.
  def self.find_open_plcc_tasks_for_servers(sam_customer, sam_servers, subcommunity=nil)
    plcc_tasks = Array.new
    
    sam_servers.each do |sam_server|
      plcc_tasks << find_open_plcc_tasks(sam_customer, sam_server, subcommunity)
    end
    
    plcc_tasks.flatten!
  end
  
  
  #This method is the same as the one in sami-web/task.rb
  #If you make any changes to this, make sure to change sami-web/task.rb also
  def self.find_open_plcc_tasks(sam_customer, sam_server=nil, subcommunity=nil)
    task_type = TaskType.find_by_code(TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE)
    joins_clause = "t"
    conditions_clause = "t.task_type_id = ? and t.sam_customer_id = ? and t.status not in (?, ?)"
    conditions_clause_fillins = [task_type.id, sam_customer.id, @@CLOSED, @@OBSOLETE]
    if(subcommunity)
      joins_clause += " inner join task_params tp on (tp.task_id = t.id and tp.name = 'subcommunityId' and tp.value = #{subcommunity.id})"
    end
    if(sam_server)
      joins_clause += " inner join task_params tp2 on (tp2.task_id = t.id and tp2.name = 'seatPoolId')"
      joins_clause += " inner join seat_pool sp on tp2.value=sp.id"
      joins_clause += " inner join sam_server ss on sp.sam_server_id=ss.id"
      conditions_clause += " and ss.id = ?"
      conditions_clause_fillins << sam_server.id
    end
    
    Task.find(:all, :select => "t.*", :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten)
  end
  
  # Get net sum of all plcc tasks for a particular subcommunity at a customer
  # For server deactivation page
  def self.net_sum_of_plcc_tasks(sam_customer, subcommunity)
  	net_sum = 0
  	task_type_code = TaskType.find_by_code(TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE)
  	if(sam_customer && subcommunity)
  	  joins_clause = "t inner join task_params tp_subcom on (tp_subcom.task_id = t.id and tp_subcom.name = 'subcommunityId' and tp_subcom.value = #{subcommunity.id})"
      joins_clause += " inner join task_params tp_delta on (tp_delta.task_id = t.id and tp_delta.name = 'delta')"
      conditions_clause = "t.task_type_id = ? and t.sam_customer_id = ? and t.status != 'c'"
      conditions_clause_fillins = [task_type_code, sam_customer.id]
      
      deltas = Task.find(:all, :select => "tp_delta.value as delta_value", :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten)
  	
  	  deltas.each do |delta|
  	  	net_sum += Integer(delta.delta_value)
  	  end
  	end
  	
  	return net_sum;
  end
  
  def self.search(params, limit=-1, sortby="t.id")
    conditions_clause_str = ""
    conditions_clause_fillins = []
    mailing_address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    joins_clause_str = "t inner join task_types tt on t.task_type_id = tt.id left join sam_customer sc on t.sam_customer_id = sc.id "
    joins_clause_str += "left join task_events te on t.last_task_event_id = te.id left join users u on te.source_user_id = u.id "
    select_clause_str = "distinct t.id, tt.id as task_type_id, tt.code as task_type_code, tt.description as task_type_description, t.status, t.created_at, sc.id as sam_customer_id, sc.name as sam_customer_name, te.created_at as task_closed_at"
    select_clause_str += ", te.comment, u.first_name as closed_by_first_name, u.last_name as closed_by_last_name"
    if (params[:task_type_id] and !params[:task_type_id].empty?)
      task_type = TaskType.find(params[:task_type_id])
      conditions_clause_str += "tt.id = ? "
      conditions_clause_fillins << task_type.id
      case (task_type.code)
        when TaskType.PENDING_ENTITLEMENT_CODE then
          begin
            conditions_clause_str += "and eot.code = 'B' "
			      joins_clause_str += "inner join task_params tp_e on (tp_e.task_id = t.id and tp_e.name = 'entitlementId') "
            joins_clause_str += "inner join entitlement e on tp_e.value = e.id inner join product p on e.product_id = p.id "
            joins_clause_str += "inner join entitlement_org eo on eo.entitlement_id = e.id inner join entitlement_org_type eot on eo.entitlement_org_type_id = eot.id "
            joins_clause_str += "inner join org o on eo.org_id = o.id "
            select_clause_str += ", e.id as entitlement_id, e.tms_entitlementid, e.order_num, e.invoice_num, p.description as product_description, e.license_count "
          end
        else joins_clause_str += "left join org o on sc.root_org_id = o.id "
      end
    else (params[:task_type_id].nil? or params[:task_type_id].empty?)
      joins_clause_str += "left join alert_instance ai on ai.task_id = t.id "
      joins_clause_str += "left join entitlement e on ai.entitlement_id = e.id left join product p on e.product_id = p.id "
      joins_clause_str += "left join entitlement_org eo on eo.entitlement_id = e.id left join entitlement_org_type eot on eo.entitlement_org_type_id = eot.id "
      joins_clause_str += "left join org o on eo.org_id = o.id "
      if (params[:bill_to_ucn] and !params[:bill_to_ucn].empty?)
        conditions_clause_str += "eot.code = 'B' "
      elsif (params[:ship_to_ucn] and !params[:ship_to_ucn].empty?)
        conditions_clause_str += "eot.code = 'S' "
      end
      select_clause_str += ", e.id as entitlement_id, e.tms_entitlementid, e.order_num, e.invoice_num, p.description as product_description, e.license_count "
    end
    
    joins_clause_str += "left join customer c on o.customer_id = c.id left join customer_address ca on (ca.customer_id = c.id and ca.address_type_id = #{mailing_address_type.id})"
    
   

    
    if (params[:id] and !params[:id].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " t.id = ?"
      conditions_clause_fillins << params[:id]
    end
    if (!params[:tms_entitlementid].nil? && !params[:tms_entitlementid].empty?)
      # if the TMS entitlement ID was specified, then there's no reason to search on any other parameters
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " e.tms_entitlementid = ?"
      conditions_clause_fillins << params[:tms_entitlementid]
    end
    if (params[:task_status] and !params[:task_status].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " t.status = ?"
      conditions_clause_fillins << params[:task_status]
    end
    if (!params[:sam_customer_id].nil? and !params[:sam_customer_id].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " t.sam_customer_id = ?"
      conditions_clause_fillins << params[:sam_customer_id]
    end
    
    # Test task created_at time
    if (!params[:task_created_at_start_date].empty? and !params[:task_created_at_end_date].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " t.created_at between '#{params[:task_created_at_start_date]} #{params[:task_created_at_start_time]}' and '#{params[:task_created_at_end_date]} #{params[:task_created_at_end_time]}'"
    elsif (!params[:task_created_at_start_date].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " t.created_at >= '#{params[:task_created_at_start_date]} #{params[:task_created_at_start_time]}'"
    elsif (!params[:task_created_at_end_date].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " t.created_at <= '#{params[:task_created_at_end_date]} #{params[:task_created_at_end_time]}'"
    end
    
    # Test task closed_at time
    if (!params[:task_closed_start_date].empty? and !params[:task_closed_end_date].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " te.created_at between '#{params[:task_closed_start_date]} #{params[:task_closed_start_time]}' and '#{params[:task_closed_end_date]} #{params[:task_closed_end_time]}'"
    elsif (!params[:task_closed_start_date].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " te.created_at >= '#{params[:task_created_at_start_date]} #{params[:task_closed_start_time]}'"
    elsif (!params[:task_closed_end_date].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " te.created_at <= '#{params[:task_closed_end_date]} #{params[:task_closed_end_time]}'"
    end
    
    if (!params[:closed_by_user_id].nil? && !params[:closed_by_user_id].empty?)
      conditions_clause_str += " and" if !conditions_clause_str.empty?
      conditions_clause_str += " t.status = ? and te.source_user_id = ?"
      conditions_clause_fillins << Task.CLOSED
      conditions_clause_fillins << params[:closed_by_user_id]
    end
    
    if (!params[:order_num].nil? && !params[:order_num].empty?)
      conditions_clause_str += " and" if !conditions_clause_str.empty?
      conditions_clause_str += " e.order_num = ?"
      conditions_clause_fillins << params[:order_num]
    end
    if (!params[:order_num].nil? && !params[:invoice_num].empty?)
      conditions_clause_str += " and" if !conditions_clause_str.empty?
      conditions_clause_str += " e.invoice_num = ?"
      conditions_clause_fillins << params[:invoice_num]
    end
    
    if (params[:bill_to_ucn] and !params[:bill_to_ucn].empty?)
      bill_to_org = Org.find(:first, :select => "org.*", :joins => "inner join entitlement_org eo on eo.org_id = org.id 
                                                           inner join customer c on org.customer_id = c.id
                                                           inner join entitlement_org_type eot on eo.entitlement_org_type_id = eot.id", 
                                        :conditions => ["c.ucn = ? and eot.code = ?", params[:bill_to_ucn], EntitlementOrgType.BILL_TO_CODE])
      return [] if bill_to_org.nil?
      conditions_clause_str += " and" if !conditions_clause_str.empty?
      conditions_clause_str += " eo.org_id = ?"
      conditions_clause_fillins << bill_to_org.id
    end
    if (params[:ship_to_ucn] and !params[:ship_to_ucn].empty?)
      ship_to_org = Org.find(:first, :select => "org.*", :joins => "inner join entitlement_org eo on eo.org_id = org.id 
                                                           inner join customer c on org.customer_id = c.id
                                                           inner join entitlement_org_type eot on eo.entitlement_org_type_id = eot.id", 
                                        :conditions => ["c.ucn = ? and eot.code = ?", params[:ship_to_ucn], EntitlementOrgType.SHIP_TO_CODE])
      return [] if ship_to_org.nil?
      conditions_clause_str += " and" if !conditions_clause_str.empty?
      conditions_clause_str += " eo.org_id = ?"
      conditions_clause_fillins << ship_to_org.id
    end
    
    if (!params[:license_count].nil? && !params[:license_count].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += "e.license_count = ?"
      conditions_clause_fillins << params[:license_count].to_i
    end
    
    if (!params[:entitlement_type_id].nil? && !params[:entitlement_type_id].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += "e.order_type_id = ?"
      conditions_clause_fillins << params[:entitlement_type_id]
      joins_clause_str += " inner join order_type ot on e.order_type_id = ot.id"
      select_clause_str += ", ot.description"
    end
    
    if (params[:state_id] and !params[:state_id].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      #joins_clause_str += " inner join org on sc.root_org_id = org.id inner join customer c on org.customer_id = c.id inner join customer_address ca on ca.customer_id = c.id inner join state_province sp on ca.state_province_id = sp.id"
      conditions_clause_str += "ca.state_province_id = ?"
      conditions_clause_fillins << params[:state_id]
      #select_clause_str += ", sp.name as state_name"
    end
    
    if(limit > 0)
      return Task.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                      :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :order => sortby, :limit => limit)
    else #negative value of limit indicates no limit
      return Task.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                      :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :order => sortby)
    end
  end
  
  def self.all_counts(user)
  	sql = "select count(t.id) as task_count, t.status, tt.user_type, tt.id as task_type_id, tt.code, tt.description 
			from tasks t inner join task_types tt on (t.task_type_id = tt.id and t.status not in ('c','z') and tt.code in ('PLCC','LCD','SCLA','LCIP'))
			group by tt.code, t.status"
    Task.find_by_sql(sql)
  end
  
  def self.count_open_tasks_by_state_province
    Task.find(:all, :select => "sp.name, count(*) as task_count", :joins => "inner join state_province sp on tasks.state_province_id = sp.id",
          :conditions => "status = 'u' or status = 'a'", :group => "sp.id", :order => "sp.name")
  end
  
  def currently_assigned_user
    event_size = self.task_events.length
    self.task_events[event_size-1].target_user
  end
  
  def alert
    self.alert_instances[0].alert
  end
  
  def self.group_open_tasks_for_state(user_type, state_province_id)
    Task.find(:all, :select => "a.description, count(*) as task_count",
              :joins => "t inner join task_types tt on t.task_type_id = tt.id", :conditions => ["tt.user_type = ? and t.status != 'c' and t.state_province_id = ?", user_type, state_province_id],
              :group => "tt.id", :order => "tt.description")
  end
  
  def self.group_open_tasks_by_type(user_type)
    conditions_clause = ""
    if (user_type != User.TYPE_ADMIN)
      conditions_clause += ("tt.user_type = '" + user_type + "' and ")
    else
      conditions_clause += "tt.user_type is not null and "
    end
    conditions_clause += "(t.status = 'u' or t.status = 'a')"
    Task.find(:all, :select => "tt.id, tt.description, count(distinct(t.id)) as task_count",
              :joins => "t inner join task_types tt on t.task_type_id = tt.id", :conditions => conditions_clause,
              :group => "tt.id", :order => "tt.description")
  end
  
  def self.find_currently_assigned_tasks(user_id, task_type_id, limit)
    conditions_clause = ""
    if !user_id.nil?
      conditions_clause += "tasks.current_user_id = " + user_id
    else
      conditions_clause += "tasks.status = '" + Task.ASSIGNED + "'"
    end
    if (alert_id)
      conditions_clause += " and tt.id = " + task_type_id.to_s
      Task.find(:all, :select => "distinct tasks.*",
              :joins => "inner join task_types tt on tasks.task_type_id = tt.id",
              :conditions => conditions_clause, :order => "tasks.priority desc", :limit => limit)
    else
      Task.find(:all, :conditions => conditions_clause, :order => "tasks.priority desc", :limit => limit)
    end
  end
  
  
  # Finds all tasks for a given SAM EE Customer
  def self.find_task_summaries_for_sam_customer(sam_customer_id)
    Task.find(:all, :select => "t.*, tt.description, sp.name, u.first_name, u.last_name", 
                :joins => "t inner join task_types tt on t.task_type_id = tt.id
                           inner join state_province sp on t.state_province_id = sp.id 
                           left join users u on t.current_user_id = u.id", 
                :conditions => ["t.sam_customer_id = ?", sam_customer_id], :order => "t.created_at desc")
  end
  
  
  
  def self.find_currently_unassigned_tasks(alert_id, limit)
    Task.find(:all, :select => "distinct t.*, ai.alert_id",
              :joins => "t inner join alert_instance ai on ai.task_id = t.id
                         inner join alert a on ai.alert_id = a.id",
              :conditions => ["a.user_type is not null and a.id = ? and t.status = ?", alert_id, Task.UNASSIGNED],
              :order => "t.priority desc", :limit => limit)
  end
  
  
  ####################
  # COMPOUND METHODS #
  ####################
  
  
  def self.build_task_packages(user_id, code, status, max = 50, sort_order = "task_date_desc")
    logger.info("build_task_packages entered")
    logger.info("code: #{code}")
    if (code)    
      case (code)
        when TaskType.PENDING_ENTITLEMENT_CODE then (task_list_result_set = Task.find_unassigned_order_tasks(status, user_id))
      end
      logger.info("task_list_result_set length: #{task_list_result_set.length}")
      # build the tasks hash with task_id as key, and then convert it to an array
      task_set_as_array = build_task_results_hash(task_list_result_set).to_a
      logger.info("task_set_as_array length: #{task_set_as_array.length}")
      # strip down to the max display length, to optimize the subsequent processing
      logger.info("Task.MAX_TASKS_DISPLAYED: #{max}")
      case(sort_order)
      	when "product" then task_set_as_array.sort! {|a,b| a[1][0].product_name <=> b[1][0].product_name}
      	when "product_desc" then task_set_as_array.sort! {|a,b| b[1][0].product_name <=> a[1][0].product_name}
      	when "priority" then task_set_as_array.sort! {|a,b| a[1][0].priority <=> b[1][0].priority}
     	when "priority_desc" then task_set_as_array.sort! {|a,b| b[1][0].priority <=> a[1][0].priority}
     	when "task_date" then task_set_as_array.sort! {|a,b| a[1][0].created_at <=> b[1][0].created_at}
     	else task_set_as_array.sort! {|a,b| b[1][0].created_at <=> a[1][0].created_at}
      end
      
      number_of_tasks = task_set_as_array.length
      if (number_of_tasks > max)
        task_set_as_array_result = task_set_as_array.slice(0,max)
      else
        task_set_as_array_result = task_set_as_array
      end
      logger.info("task_set_as_array_result new length: #{task_set_as_array_result.length}")
    else
      # get the unassigned entitlement task result array
      non_uo_task_set_as_array = build_task_results_hash(Task.find_tasks_filtering(TaskType.UNASSIGNED_ENTITLEMENT_CODE, status, user_id)).to_a
      # get the non-unassigned entitlement task result array
      uo_task_set_as_array = build_task_results_hash(Task.find_unassigned_order_tasks(status, user_id)).to_a
      task_set_as_array_result = non_uo_task_set_as_array.concat(uo_task_set_as_array).sort! {|a,b| b[1][0].priority <=> a[1][0].priority}
      number_of_tasks = task_set_as_array_result.length
    end
    
    #return task_packages, number_of_tasks
    return task_set_as_array_result, number_of_tasks
  end
  
  private
  
  # The following method takes an array of task-related results, each of which has an id field representing a task_id.
  # It returns a hash of arrays, where the hash key is the task_id  
  def self.build_task_results_hash(task_results)
    # first build the hash using task id as the key
    task_set_results = {}
    task_results.each do |tlrs|
      hash_key = tlrs.id
      if (task_set_results[hash_key].nil?)
        task_set_results[hash_key] = Array.new(1,tlrs)
      else
        task_set_results[hash_key] << tlrs
      end
    end
    return task_set_results
  end
  
  
  # The following method returns entitlement_org records that are related to:
  #  - entitlements that have corresponding alert_instance records that represent unassigned order tasks with status 'status' and assigned to user_id 'user_id'.
  # If user_id is nil, then the method looks for all such records related to unassigned tasks for unassigned orders.
  # The following fields are present in the returned array:
  #  - id:  the task ID
  #  - created_at:  the date the task was created
  #  - sam_customer_id:  the SAM Customer ID related to the task
  #  - status:  the status of the task
  #  - state_province_id:  the state_province_id of the task
  #  - city_name:  the city of the entitlement_org related to the entitlement related to the task
  #  - county_code:  the county code of the entitlement_org related to the entitlement related to the task
  #  - zip_code:  the zip code of the entitlement_org related to the entitlement related to the task
  #  - state_code:  the state code related to the task
  #  - priority:  the priority of the task
  #  - current_user_id:  the user_id of the user currently assigned to the task
  #  - last_task_event_id:  the id of the last task event related to the task
  #  - task_type_id:  the id of the task type for the task
  #  - entitlement_id:  the ID of the entitlement that is related to the task
  #  - tms_entitlement_id:  the TMS Entitlement ID related to the entitlement for the task
  #  - order_num:  the order number of the entitlement related to the task
  #  - invoice_num:  the invoice number of the entitlement related to the task
  #  - org_id:  the org_id of the entitlement_org related to the entitlement related to the task
  #  - ucn:  the UCN of the entitlement_org related to the entitlement related to the task
  #  - org_name:  the name of the entitlement_org related to the entitlement related to the task
  #  - product_name:  the name of the product related to the entitlement related to the task
  #  - license_count:  the license count of the entitlement related to the task
  #  - reason_unassigned:  the textual reason that the entitlement could not be assigned to a SAM Customer
  #  - code:  the code for the task type of the task
  #  - entitlement_org_type_description:  the description of the entitlement org type related to the entitlement related to the task
  #  - entitlement_org_type_code:  the code of the entitlement org type related to the entitlement related to the task
  #  - ordered:  the order date of the entitlement related to the task
  #  - entitlement_created_at:  the created_at date of the entitlement related to the task
  def self.find_unassigned_order_tasks(status, user_id = nil)
    task_type = TaskType.find_by_code(TaskType.UNASSIGNED_ENTITLEMENT_CODE)
    mailing_address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    select_clause = "t.*, e.id as entitlement_id, e.tms_entitlementid as tms_entitlement_id, e.order_num, e.invoice_num, eo.org_id as org_id,
                     eo.ucn, eo.name as org_name, p.description as product_name, e.license_count, tp.value as reason_unassigned, tt.code, tt.description as task_type_description,
                     eot.description as entitlement_org_type_description, eot.code as entitlement_org_type_code, e.ordered, e.created_at as entitlement_created_at, ifnull(sp.code,'') as state_code,
                     ifnull(ca.city_name,'') as city_name, ifnull(ca.county_code,'') as county_code, ifnull(ca.zip_code,'') as zip_code, ca.address_line_1, ca.address_line_2, ca.address_line_3"
    joins_clause = "t inner join task_params tp1 on (tp1.task_id = t.id and tp1.name = 'entitlementId')
                    inner join entitlement e on tp1.value = e.id
                    inner join product p on e.product_id = p.id
                    inner join entitlement_org eo on eo.entitlement_id = e.id
                    inner join entitlement_org_type eot on eo.entitlement_org_type_id = eot.id
                    inner join customer c on eo.ucn = c.ucn
                    inner join customer_address ca on ca.customer_id = c.id
                    inner join country on ca.country_id = country.id
                    inner join task_types tt on t.task_type_id = tt.id					
                    left join state_province sp on ca.state_province_id = sp.id
                    left join task_params tp on (tp.task_id = t.id and tp.name = 'exceptionType')"
    conditions_clause_str = "t.task_type_id = ? and ca.address_type_id = ?"
    conditions_clause_fillins = [task_type.id, mailing_address_type.id]
    if (status == Task.ASSIGNED)
      if (user_id)
        joins_clause += " inner join task_events te on t.last_task_event_id = te.id inner join users u on te.source_user_id = u.id"
        select_clause += ", u.last_name as source_user_last_name, u.first_name as source_user_first_name, te.created_at as date_assigned"
        conditions_clause_str += " and t.status = 'a' and t.current_user_id = ?"
        conditions_clause_fillins << user_id
      else
        joins_clause += " inner join users u on t.current_user_id = u.id"
        select_clause += ", u.id as target_user_id, u.last_name as assigned_user_last_name, u.first_name as assigned_user_first_name"
        conditions_clause_str += " and t.status = 'a' and t.current_user_id is not null"
      end
    else
      conditions_clause_str += " and t.status = ?"
      conditions_clause_fillins << status
    end
    orders_clause = "t.id, entitlement_org_type_description"
    conditions_clause_str += " and (eot.code = 'B' or eot.code = 'S')"
    conditions_clause = [conditions_clause_str, conditions_clause_fillins].flatten
    Task.find(:all, :select => select_clause, :joins => joins_clause, :conditions => conditions_clause, :order => orders_clause)
  end
  
  def self.find_entitlement_org_info(task)
    mailing_address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    select_clause = "t.*, ai.id as alert_instance_id, e.id as entitlement_id, e.tms_entitlementid as tms_entitlement_id, e.order_num, e.invoice_num, eo.org_id as org_id,
                     eo.ucn, eo.name as org_name, p.description as product_name, e.license_count, tp.value as reason_unassigned, tt.code,
                     eot.description as entitlement_org_type_description, eot.code as entitlement_org_type_code, e.ordered, e.created_at as entitlement_created_at, ifnull(sp.code,'') as state_code,
                     ifnull(ca.city_name,'') as city_name, ifnull(ca.county_code,'') as county_code, ifnull(ca.zip_code,'') as zip_code, country.name as country_name, tt.description as task_type_description, ca.address_line_1, ca.address_line_2, ca.address_line_3"
    joins_clause = "t inner join alert_instance ai on ai.task_id = t.id
                    inner join entitlement e on ai.entitlement_id = e.id
                    inner join product p on e.product_id = p.id
                    inner join entitlement_org eo on eo.entitlement_id = e.id
                    inner join entitlement_org_type eot on eo.entitlement_org_type_id = eot.id
                    inner join customer c on eo.ucn = c.ucn
                    inner join customer_address ca on ca.customer_id = c.id
                    inner join task_types tt on t.task_type_id = tt.id
                    left join state_province sp on ca.state_province_id = sp.id
                    inner join country on ca.country_id = country.id
                    left join task_params tp on (tp.task_id = t.id and tp.name = 'exceptionType')"
    Task.find(:all, :select => select_clause, :joins => joins_clause, :conditions => ["t.id = ? and ca.address_type_id = ? and (eot.code = 'B' or eot.code = 'S')", task.id, mailing_address_type.id],
              :order => "entitlement_org_type_description")
  end
  
  def self.find_tasks_filtering(task_code, status, user_id = nil)
    filter_task_type = TaskType.find_by_code(task_code)
    select_clause = "t.*, sc.name as sam_customer_name, tt.code, tt.description as task_type_description, te.created_at as date_assigned, u.last_name as source_user_last_name, u.first_name as source_user_first_name"
    joins_clause = "t inner join task_types tt on t.task_type_id = tt.id inner join sam_customer sc on t.sam_customer_id = sc.id 
                    inner join task_events te on t.last_task_event_id = te.id inner join users u on te.source_user_id = u.id"
    conditions_clause_str = "tt.id != ?"
    conditions_clause_fillins = [filter_task_type.id]
    if (user_id and status == Task.ASSIGNED)
      conditions_clause_str += " and t.status = 'a' and t.current_user_id = ?"
      conditions_clause_fillins << user_id
    end
    conditions_clause = [conditions_clause_str, conditions_clause_fillins].flatten
    Task.find(:all, :select => select_clause, :joins => joins_clause, :conditions => conditions_clause, :order => "t.priority desc")
  end
  
  def self.find_user_list_with_task_counts
    edit_permission = Permission.find_by_code('CUSTSERV-EDIT')
    User.find(:all, :select => "u.id, u.first_name, u.last_name, s.id as session_id, count(distinct t.id) as number_of_tasks",
              :joins => "u left join sessions s on s.user_id = u.id left join tasks t on t.current_user_id = u.id
                         inner join user_permission u_p on (u_p.user_id = u.id and u_p.permission_id = #{edit_permission.id})",
              :conditions => "u.active = true and u.user_type != 'c'", :order => "u.last_name", :group => "u.id")
  end


	def self.index_by_task_type_code(task_type_code)
		task_type = TaskType.find_by_code(task_type_code)
		Task.find(:all, :conditions => ["task_type_id = ?", task_type.id])
	end
  
end


# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(10)     not null, primary key
#  created_at         :datetime        not null
#  sam_customer_id    :integer(10)
#  status             :string(255)     default("u"), not null
#  state_province_id  :integer(10)
#  priority           :integer(10)     default(0), not null
#  current_user_id    :integer(10)
#  last_task_event_id :integer(10)
#  task_type_id       :integer(10)     not null
#

