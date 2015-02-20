class FinderController < ApplicationController

  before_filter :load_view_support_libraries
  
  layout "default"

  def index
  @state_province_list = [["-any-", nil]].concat(StateProvince.find(:all, :conditions => "display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
  @true_or_false_options = [["Yes or No", "0"],["Yes", "1"],["No", "2"]]
	@os_family_options = [["-any-", nil],["Windows", "WINDOWS"],["Linux", "LINUX"],["OSX", "OSX"]]
	@cpu_bits_options = [["-any-", nil],["BITS_32", "BITS_32"],["BITS_64", "BITS_64"]]
	@os_series_options = [
      ["-any-",           nil],
      ["WIN_2000",     "WIN_2000"],
      ["WIN_XP",       "WIN_XP"],
      ["WIN_2003",     "WIN_2003"],
      ["WIN_VISTA",    "WIN_VISTA"],
      ["MAC_10_3",     "MAC_10_3"],
      ["MAC_10_4",     "MAC_10_4"],
      ["MAC_10_5",     "MAC_10_5"]
    ]
    get_entitlement_reference_info
    get_org_reference_info
    get_task_reference_info
    get_sam_customer_reference_info
	get_email_type_reference_info
    get_auth_user_type_reference_info
	get_agent_plugins_info
  end

  def quick_search
    max_display_records = 1000; #limit the number of records displayed at once. Note that the exported .csv will have the complete result set
    params[:sort] ||= "id"
    @sort_order = params[:sort]
    @limit = 1000
    @errors = []
    case params[:search_category]
      when "sam_customers" then
        begin
          @num_rows_reported = 0
          params[:sam_customer] = {}
          params[:sam_customer][:ucn] = params[:search_key]
          @sam_customers = get_sam_customers(@sort_order, max_display_records)
          @num_rows_reported = @sam_customers.length
          logger.info("we have #{@sam_customers.length} customers from ucn")
          if (@num_rows_reported != 1)
            params[:sam_customer][:ucn] = ""
            params[:sam_customer][:sam_customer_id] = params[:search_key]
            @sam_customers.concat(get_sam_customers(@sort_order, max_display_records))
            @num_rows_reported = @sam_customers.length
          end
          if (@num_rows_reported != 1)
            params[:sam_customer][:sam_customer_id] = ""
            params[:sam_customer][:name] = params[:search_key]
            @sam_customers.concat(get_sam_customers(@sort_order, max_display_records))
            @num_rows_reported = @sam_customers.length
          end
          if (@num_rows_reported != 1)
            render(:partial => "sam_customers/search")
          else
            render(:text => sam_customer_path(@sam_customers[0].id))
          end
        end
      when "entitlements" then
        begin
          params[:entitlement] = {}
          params[:entitlement][:tms_entitlementid] = params[:search_key]
          @entitlements = get_entitlements(@sort_order, max_display_records)
          params[:entitlement][:tms_entitlementid] = ""
          params[:entitlement][:order_num] = params[:search_key]
          @entitlements.concat(get_entitlements(@sort_order, max_display_records))
          @num_rows_reported = @entitlements.length
          if (@num_rows_reported != 1 or (@num_rows_reported == 1 and @entitlements.first.sam_customer_id.nil?))
            render(:partial => "entitlements/search")
          else
            render(:text => sam_customer_entitlement_path(@entitlements[0].sam_customer_id, @entitlements[0].id))
          end
        end
      when "emails" then
        begin
          params[:email_message] = {}
          params[:email_message][:to_address] = params[:search_key]
          @email_messages = get_email_messages(@sort_order, max_display_records)
          @num_rows_reported = @email_messages.length
          if (@num_rows_reported != 1)
            render(:partial => "email_messages/search")
          else
            render(:text => email_message_path(@email_messages[0].id))
          end
        end
      when "sam_servers" then
        begin
          has_additional_info = false;
          params[:sam_server] = {}
          params[:sam_server][:sam_server_id] = params[:search_key]
          @sam_servers = get_sam_servers(@sort_order, max_display_records)
          @num_rows_reported = @sam_servers.length
          if (@num_rows_reported != 1)
            #render(:partial => "sam_servers/search")
            render(:partial => "sam_servers/search", :locals => {:has_additional_info => has_additional_info}) #render partial
          else
            # shouldn't happen since we're just searching by id right now
            render(:text => sam_customer_sam_server_path(@sam_servers[0].sam_customer_id, @sam_servers[0].id), :locals => {:has_additional_info => false})
          end
        end
      when "processes" then
         begin
           params[:processes] = {}
           params[:processes][:process_id] = params[:search_key]
           @process_messages = get_process_messages(@sort_order, max_display_records)
           @num_rows_reported = @processes.length
           render(:partial => "processes/search") 
        end
       
        when "orgs" then
         begin
           params[:org] = {}
           params[:org][:ucn] = params[:search_key]
           @orgs = get_orgs(@sort_order, max_display_records)
           @num_rows_reported = @orgs.length
           render(:partial => "orgs/search") 
       end
       
       when "tasks" then
         begin
           params[:task] = {}
           params[:task][:id] = params[:search_key]
           @tasks = get_tasks(@sort_order, max_display_records)
           @num_rows_reported = @tasks.length
           @pending_entitlement_task_type = TaskType.find_by_code(TaskType.PENDING_ENTITLEMENT_CODE)
           render(:partial => "tasks/search") 
       end


      when "auth_users" then
        params[:auth_user] = {}
        params[:auth_user][:id] = params[:search_key]
        @auth_users = get_auth_users(@sort_order, MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_DEFAULT) #limit the number of records displayed at once. Note that the exported .csv will have the complete result set
        params[:auth_user][:id] = ""
        params[:auth_user][:username] = params[:search_key]
        @auth_users.concat(get_auth_users(@sort_order, MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_DEFAULT))
        @num_rows_reported = @auth_users.length
        if (@num_rows_reported != 1)
          render(:partial => "auth_users/search")
        else
          render(:text => sam_customer_auth_user_path(@auth_users[0].sam_customer_id, @auth_users[0].id))
        end
       end
  end

  def sam_customer_finder
    product_type_list = [["-any-", nil]].concat(Product.find(:all, :order => "description").collect {|p| [p.description, p.id]})
    #product_group_list = [["-any-", nil]].concat(ProductGroup.find(:all, :order => "description").collect {|pg| [pg.description, pg.id]})
    true_or_false_options = [["Yes or No", "0"],["Yes", "1"],["No", "2"]]
    state_province_list = [["-any-", nil]].concat(StateProvince.find(:all, :conditions => "display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
    community_list = [["-any-", nil]].concat(Community.find(:all, :order => "name").collect{|c| [c.name, c.id]})
    render(:partial => "sam_customer_search", :locals => {:community_list => community_list, :true_or_false_options => true_or_false_options, :product_type_list => product_type_list,
              :state_province_list => state_province_list})
  end

  def entitlement_finder
    state_province_list = [["-any-", nil]].concat(StateProvince.find(:all, :select => "id, display_name", :conditions => "display_name IS NOT null AND display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
    product_type_list = [["-any-", nil]].concat(Product.find(:all, :select => "id, description", :order => "description").collect {|p| [p.description, p.id]})
    product_group_list = [["-any-", nil]].concat(ProductGroup.find(:all, :select => "id, description", :order => "description").collect {|pg| [pg.description, pg.id]})
    order_type_list = [["-any-", nil]].concat(OrderType.find(:all, :order => "description").collect {|et| [et.description, et.id]})
    sc_entitlement_type_list = [["-any-", nil]].concat(ScEntitlementType.find(:all, :order => "description").collect {|et| [et.description, et.id]})
    render(:partial => "entitlement_search", :locals => {:product_group_list => product_group_list,
		 :product_type_list => product_type_list, :order_type_list => order_type_list,
		 :sc_entitlement_type_list => sc_entitlement_type_list, :state_province_list => state_province_list})
  end

  def sam_server_finder
    state_province_list = [["-any-", nil]].concat(StateProvince.find(:all, :conditions => "display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
    true_or_false_options = [["Yes or No", "0"],["Yes", "1"],["No", "2"]]
    true_or_either_options = [["Yes or No", "0"],["Yes", "1"]]
	  os_family_options = [["-any-", nil],["Windows", "WINDOWS"],["Linux", "LINUX"],["OSX", "OSX"]]
	  cpu_bits_options = [["-any-", nil],["BITS_32", "BITS_32"],["BITS_64", "BITS_64"]]
	  os_series_options = [
      ["-any-",           nil],
      ["WIN_2000",     "WIN_2000"],
      ["WIN_XP",       "WIN_XP"],
      ["WIN_2003",     "WIN_2003"],
      ["WIN_VISTA",    "WIN_VISTA"],
      ["MAC_10_3",     "MAC_10_3"],
      ["MAC_10_4",     "MAC_10_4"],
      ["MAC_10_5",     "MAC_10_5"]
    ]
    get_sam_customer_reference_info
    get_agent_plugins_info
    render(:partial => "sam_server_search", :locals => {:true_or_false_options => true_or_false_options, :true_or_either_options => true_or_either_options,
      :os_family_options => os_family_options, :cpu_bits_options => cpu_bits_options, :os_series_options => os_series_options,
      :community_list => @community_list, :agent_plugins_list => @agent_plugins_list, :state_province_list => state_province_list})
  end

  def email_finder
    get_email_type_reference_info
    render(:partial => "email_search", :locals => {:email_type_list => @email_type_list})
  end

  def task_finder
    state_province_list = [["-any-", nil]].concat(StateProvince.find(:all, :conditions => "display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
    get_task_reference_info
    get_entitlement_reference_info
    render(:partial => "task_search", :locals => {:task_type_list => @task_type_list, :user_list => @user_list, :task_status_list => @task_status_list,
            :order_type_list => @order_type_list, :state_province_list => state_province_list})
  end

  def auth_user_finder
    get_auth_user_type_reference_info
    render(:partial => "auth_user_search", :locals => {:auth_user_type_list => @auth_user_type_list})
  end

  def sam_server_report_request_finder
    @sam_server_report_request = ServerReportRequest.new
    render(:partial => "sam_server_report_request", :locals => {:sam_server_report_request => @sam_server_report_request})
  end

  def processes_finder
    render(:partial => "processes_search")
  end
  
  def orgs_finder
    get_org_reference_info
    state_province_list = [["-any-", nil]].concat(StateProvince.find(:all, :conditions => "display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
    render(:partial => "org_search", :locals => {:customer_status_list => @customer_status_list,
            :customer_group_list => @customer_group_list, :customer_type_list => @customer_type_list,
            :state_province_list => state_province_list})
  end

  private

  def get_sam_customers(sortby, limit)
    #limit defines the max number of records to return from the query. A negative indicates no limit
    case (sortby) #mapping all column view names to database fields here to keep view seperate from model
      when "customer_name" then orders_clause = "name"
      when "customer_name desc" then orders_clause = "name desc"
      when "siteid" then orders_clause = "siteid"
      when "siteid desc" then orders_clause = "siteid desc"
      when "state" then orders_clause = "state_name"
      when "state desc" then orders_clause = "state_name desc"
      when "UCN" then orders_clause = "sc_ucn"
      when "UCN desc" then orders_clause = "sc_ucn desc"
      when "status" then orders_clause = "active"
      when "status desc" then orders_clause = "active desc"
      when "registration_date" then orders_clause = "registration_date"
      when "registration_date desc" then orders_clause = "registration_date desc"
      when "license_manager_status" then orders_clause = "licensing_status"
      when "license_manager_status desc" then orders_clause = "licensing_status desc"
      when "auth_status" then orders_clause = "auth_status"
      when "auth_status desc" then orders_clause = "auth_status desc"
      when "update_manager_status" then orders_clause = "update_manager_status"
      when "update_manager_status desc" then orders_clause = "update_manager_status desc"
      when "update_quiz_as_available" then orders_clause = "update_quiz_as_available"
      when "update_quiz_as_available desc" then orders_clause = "update_quiz_as_available desc"
      else orders_clause = sortby #shouldn't be reached
    end

    #put whole array from email search form into session
    #when a resubmit comes in from the user sorting the list, :email_message will not be included in the request
    if (params[:sam_customer])
      session[:sam_customer] = params[:sam_customer]
    end

    #these are also only passsed in the request from the initial search form, outside of the :sam_customer array
    session[:sam_customer][:registered_at_start_date] = params[:registered_at_start_date] || "" #always set a session value to avoid null reference, default to empty string as necesary
    session[:sam_customer][:registered_at_end_date] = params[:registered_at_end_date] || ""
    logger.info "#{params.to_yaml}"

    @limit = limit
    @sam_customers = SamCustomer.search(session[:sam_customer], limit, orders_clause)
  end

  def get_entitlements(sortby, limit)
    orders_clause = entitlement_sort_by_param_finder(sortby)

    #put whole array from search form into session
    #when a resubmit comes in from the user sorting the list, :entitlement will not be included in the request
    if(params[:entitlement]) #don't overwrite session with null if there are no new params
      session[:entitlement] = params[:entitlement]
    end

    #these are also only passsed in the request from the initial search form, outside of the :entitlement array
    if (params[:created_at_start_date])
      session[:entitlement][:created_at_start_date] = params[:created_at_start_date]
    end
    if (params[:created_at_end_date])
      session[:entitlement][:created_at_end_date] = params[:created_at_end_date]
    end
    if (params[:order_start_date])
      session[:entitlement][:order_start_date] = params[:order_start_date]
    end
    if (params[:order_end_date])
      session[:entitlement][:order_end_date] = params[:order_end_date]
    end

    if (params[:entitlement] or params[:created_at_start_date] or params[:created_at_end_date] or params[:order_start_date] or params[:order_end_date])
      session[:entitlement].each_pair {|k,v| v.strip!}
    end

    @limit = limit
    return Entitlement.search(session[:entitlement], limit, orders_clause)
  end

  def get_sam_servers(sortby, limit)
    case (sortby) #mapping all column view names to database fields here to keep view seperate from model
      when "sam_server_id" then orders_clause = "id"
      when "sam_server_id desc" then orders_clause = "id desc"
      when "sam_server_name" then orders_clause = "name"
      when "sam_server_name desc" then orders_clause = "name desc"
      when "registered_at" then orders_clause = "created_at"
      when "registration_siteid desc" then orders_clause = "value desc"
      when "registration_siteid" then orders_clause = "value"
      when "registered_at desc" then orders_clause = "created_at desc"
      when "status" then orders_clause = "active"
      when "status desc" then orders_clause = "active desc"
      when (SAM_CUSTOMER_TERM+"_id") then orders_clause = "sam_customer_id"
      when (SAM_CUSTOMER_TERM+"_id desc") then orders_clause = "sam_customer_id desc"
      when (SAM_CUSTOMER_TERM+"_name") then orders_clause = "sam_customer_name"
      when (SAM_CUSTOMER_TERM+"_name desc") then orders_clause = "sam_customer_name desc"
      when (SAM_CUSTOMER_TERM+"_ucn") then orders_clause = "ucn"
      when (SAM_CUSTOMER_TERM+"_ucn desc") then orders_clause = "ucn desc"
      when "guid" then orders_clause = "guid"
      when "guid desc" then orders_clause = "guid desc"
      else orders_clause = sortby #shouldn't be reached
    end

    #put whole array from search form into session
    #when a resubmit comes in from the user sorting the list or generating csv, :sam_server will not be included in the request
    if (!params.nil? && params[:sam_server])
      session[:sam_server] = params[:sam_server]
    end

    #these are also only passsed in the request from the initial search form, outside of the :sam_server array
    if(!params.nil? && params[:registered_at_start_date])
      session[:sam_server][:registered_at_start_date] = params[:registered_at_start_date]
    elsif(!session[:sam_server][:registered_at_start_date])
      session[:sam_server][:registered_at_start_date] = "" #always set a session value to avoid null reference, default to empty string as necesary
    end
    if(!params.nil? && params[:registered_at_end_date])
      session[:sam_server][:registered_at_end_date] = params[:registered_at_end_date]
    elsif(!session[:sam_server][:registered_at_end_date])
      session[:sam_server][:registered_at_end_date] = ""
    end
    if(!params.nil? && params[:checked_in_since]) #don't overwrite session value with a null value
      session[:sam_server][:checked_in_since] = params[:checked_in_since]
    end
    logger.info "#{params.to_yaml}"

    @limit = limit
    @sam_servers = SamServer.search(session[:sam_server], limit, orders_clause)
  end

  def entitlement_sort_by_param_finder(sortby) #used for Entitlement Finder, has different fields than details table on customer entitlment page
    case (sortby) #mapping all column view names to database fields here to keep view seperate from model
      when "id" then "id"
      when "id desc" then "id desc"
      when "tms_entitlementid" then "tms_entitlementid"
      when "tms_entitlementid desc" then "tms_entitlementid desc"
      when "created_at" then "created_at"
      when "created_at desc" then "created_at desc"
      when "order_date" then "ordered"
      when "order_date desc" then "ordered desc"
      when PRODUCT_TERM then "p.description"
      when (PRODUCT_TERM+" desc") then "p.description desc"
      when "license_count" then "license_count"
      when "license_count desc" then "license_count desc"
      when "invoice_num" then "invoice_num"
      when "invoice_num desc" then "invoice_num desc"
      when SAM_CUSTOMER_TERM then "sc.name"
      when (SAM_CUSTOMER_TERM+" desc") then "sc.name desc"
      when "state" then "display_name"
      when "state desc" then "display_name desc"
      else sortby #shouldn't be reached
    end
  end

  def get_auth_users(sortby="auth_user_id", limit=-1) #limit defines the max number of records to return from the query. A negative indicates no limit

    #put whole array from search form into session
    #when a resubmit comes in from the user sorting the list, :auth_user will not be included in the request
    if (params[:auth_user])
      session[:auth_user] = params[:auth_user]
    end
    conditions_clause = ""
    joins_clause = ""
    if (!session[:auth_user][:id].nil? && session[:auth_user][:id].length > 0)
        conditions_clause << (" AND au.id = " + session[:auth_user][:id].to_s)
    elsif (!session[:auth_user][:username].nil? && session[:auth_user][:username].length > 0)
          conditions_clause << (" AND LOWER(au.username) LIKE '%" + session[:auth_user][:username].downcase + "%'") #username is set case-sensitive in DB for login authentication, but make finder search lenient
    else
      if(!session[:auth_user][:sam_customer_id].nil? && session[:auth_user][:sam_customer_id].length > 0)
        conditions_clause << (" AND au.sam_customer_id = " + session[:auth_user][:sam_customer_id].to_s)
      end
      if(!session[:auth_user][:sam_customer_name].nil? && session[:auth_user][:sam_customer_name].length > 0)
        conditions_clause << (" AND sc.name LIKE '%" + session[:auth_user][:sam_customer_name] + "%'")
        joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        joins_clause << " INNER JOIN sam_server ss ON ssu.sam_server_id = ss.id"
        joins_clause << " INNER JOIN sam_customer sc ON ss.sam_customer_id = sc.id"
      end
      if(!session[:auth_user][:customer_ucn].nil? && session[:auth_user][:customer_ucn].length > 0)
        conditions_clause << (" AND c1.ucn LIKE '" + session[:auth_user][:customer_ucn] + "'") #o1 and c1 are for disrict, o2 and c2 are for school
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
          joins_clause << " INNER JOIN sam_server ss ON ssu.sam_server_id = ss.id"
          joins_clause << " INNER JOIN sam_customer sc ON ss.sam_customer_id = sc.id"
          joins_clause << " INNER JOIN org o1 ON sc.root_org_id = o1.id"
          joins_clause << " INNER JOIN customer c1 ON o1.customer_id = c1.id"
        end
      end
      if(!session[:auth_user][:username].nil? && session[:auth_user][:username].length > 0)
        conditions_clause << (" AND LOWER(au.username) LIKE '%" + session[:auth_user][:username].downcase + "%'") #username is set case-sensitive in DB for login authentication, but make finder search lenient
      end
      if(!session[:auth_user][:uuid].nil? && session[:auth_user][:uuid].length > 0)
        conditions_clause << (" AND au.uuid LIKE '%" + session[:auth_user][:uuid].to_s + "%'")
      end
      if(!session[:auth_user][:type].nil? && session[:auth_user][:type].length > 0 && session[:auth_user][:type] != "-any-")
        conditions_clause << (" AND au.type = '" + session[:auth_user][:type] + "'")
      end
      if(!session[:auth_user][:created_at_start].nil? && session[:auth_user][:created_at_start].length > 0)
        conditions_clause << (" AND au.created_at >= '" + session[:auth_user][:created_at_start] + "'")
      end
      if(!session[:auth_user][:created_at_end].nil? && session[:auth_user][:created_at_end].length > 0)
        conditions_clause << (" AND au.created_at <= '" + session[:auth_user][:created_at_end] + "'")
      end
      if(!session[:auth_user][:first_name].nil? && session[:auth_user][:first_name].length > 0)
        conditions_clause << (" AND ssu.first_name LIKE '%" + session[:auth_user][:first_name] + "%'")
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        end
      end
      if(!session[:auth_user][:last_name].nil? && session[:auth_user][:last_name].length > 0)
        conditions_clause << (" AND ssu.last_name LIKE '%" + session[:auth_user][:last_name] + "%'")
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        end
      end
      if(!session[:auth_user][:email].nil? && session[:auth_user][:email].length > 0)
        conditions_clause << (" AND ssu.email LIKE '%" + session[:auth_user][:email] + "%'")
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        end
      end
      if(!session[:auth_user][:sam_server_id].nil? && session[:auth_user][:sam_server_id].length > 0)
        conditions_clause << (" AND ssu.sam_server_id = " + session[:auth_user][:sam_server_id])
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        end
      end
      if(!session[:auth_user][:sam_server_name].nil? && session[:auth_user][:sam_server_name].length > 0)
        conditions_clause << (" AND ss.name LIKE '%" + session[:auth_user][:sam_server_name] + "%'")
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        end
        if(!joins_clause.include? "JOIN sam_server ")
          joins_clause << " INNER JOIN sam_server ss ON ssu.sam_server_id = ss.id"
        end
      end
      if(!session[:auth_user][:school_ucn].nil? && session[:auth_user][:school_ucn].length > 0)
        conditions_clause << (" AND c2.ucn = " + session[:auth_user][:school_ucn].to_s)
        if(!joins_clause.include? "JOIN sam_server_user ")
          joins_clause << " INNER JOIN sam_server_user ssu ON au.id = ssu.auth_user_id"
        end
        if(!joins_clause.include? "JOIN sam_server ")
          joins_clause << " INNER JOIN sam_server ss ON ssu.sam_server_id = ss.id"
        end
        joins_clause << " INNER JOIN sam_server_school_info sssi ON ss.id = sssi.sam_server_id"
        joins_clause << " INNER JOIN sam_server_school_info_user_mapping sssium ON (ssu.user_id = sssium.user_id AND sssi.sam_school_id = sssium.sam_school_id)"
        joins_clause << " INNER JOIN org o2 ON sssi.org_id = o2.id" #o1 and c1 are for disrict, o2 and c2 are for school
        joins_clause << " INNER JOIN customer c2 ON o2.customer_id = c2.id"
      end
    end
    if(conditions_clause.length > 1)
      conditions_clause.sub!("AND","WHERE") #replace the first AND with WHERE for SQL
    end
    @limit = limit #this just makes limit available to the view for info to user
    begin
      return AuthUser.find_by_sql("SELECT au.* FROM auth_user au" +
                                         joins_clause +
                                         conditions_clause +
                                         " GROUP BY au.id" +
                                         " ORDER BY " + sam_customer_auth_users_sort_by_param(sortby) +
                                         (limit < 0 ? "" : " LIMIT " + limit.to_s)
                                        )
    rescue Exception => exception
      logger.error "ERROR: SQL exception encountered during Auth Users Finder search, likely due to invalid input for one or more fields. Returning empty result set to view."
      logger.error exception.message
      return Array.new #if user gave invalid input that results in a SQL exception, just give them no results, don't allow web page to break
    end
  end

  def sam_customer_auth_users_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "auth_user_id"              then "au.id"
      when "auth_user_id_reverse"      then "au.id DESC"
      when "username"                  then "LOWER(au.username)"
      when "username_reverse"          then "LOWER(au.username) DESC"
      when "auth_user_type"            then "au.type"
      when "auth_user_type_reverse"    then "au.type DESC"
      when "uuid"                      then "au.uuid"
      when "uuid_reverse"              then "au.uuid DESC"
      when "created_at"                then "au.created_at"
      when "created_at_reverse"        then "au.created_at DESC"
      when "updated_at"                then "au.updated_at"
      when "updated_at_reverse"        then "au.updated_at DESC"
      when "enabled"                   then "au.enabled"
      when "enabled_reverse"           then "au.enabled DESC"
      when "sam_customer_id"           then "au.sam_customer_id" #note that some fields vary between table on customer page and table in finder
      when "sam_customer_id_reverse"   then "au.sam_customer_id DESC"
      when "active_token_id"           then "au.active_token_id"
      when "active_token_id_reverse"   then "au.active_token_id DESC"
      else "LOWER(au.username)" #should never be reached
    end
  end

  def get_email_messages(sortby, limit, quick_search = false)
    #limit defines the max number of records to return from the query. A negative indicates no limit
  	case (sortby)
  	  when "email_id" then orders_clause = "id"
      when "email_id_desc" then orders_clause = "id desc"
      when "email_type" then orders_clause = "description"
  	  when "email_type_desc" then orders_clause = "description desc"
  	  when "user_id" then orders_clause = "user_id"
  	  when "user_id_desc" then orders_clause = "user_id desc"
  	  when "to_address" then orders_clause = "recipient_address"
  	  when "to_address_desc" then orders_clause = "recipient_address desc"
  	  when "gen_date" then orders_clause = "generated_date"
  	  when "gen_date_desc" then orders_clause = "generated_date desc"
  	  when "sent_date" then orders_clause = "sent_date"
  	  when "sent_date_desc" then orders_clause = "sent_date desc"
	  when "cust_id" then orders_clause = "cust_id"
	  when "cust_id_desc" then orders_clause = "cust_id desc"
	  when "cust_name" then orders_clause = "cust_name"
	  when "cust_name_desc" then orders_clause = "cust_name desc"
    end

    select_clause = "distinct em.*, et.description, sc.id as cust_id, sc.name as cust_name "
    joins_clause = "em inner join email_type et on em.email_type_id = et.id left join users u on em.user_id = u.id left join sam_customer sc on u.sam_customer_id = sc.id "
    conditions_clause = "em.id is not null "
    conditions_clause_fillins = []

    #put whole array from email search form into session
    #when a resubmit comes in from the user sorting the list, :email_message will not be included in the request
    if (params[:email_message])
      session[:email_message] = params[:email_message]
    end

    if (quick_search)
      if (session[:email_message][:to_address] && !session[:email_message][:to_address].strip.empty?)
      		conditions_clause += "and em.recipient_address like ? "
      		conditions_clause_fillins << ("%" + session[:email_message][:to_address] + "%")
    	end
    else
      #use session from now on since only the initial request (not subsequent requests for sorting) will have the :email_message array in the request
    	if (session[:email_message][:email_type] && !session[:email_message][:email_type].empty?)
          conditions_clause += "and et.id = ? "
          conditions_clause_fillins << session[:email_message][:email_type].to_i
      end
      if (session[:email_message][:user_id] && !session[:email_message][:user_id].strip.empty?)
      		conditions_clause += "and em.user_id = ? "
      		conditions_clause_fillins << session[:email_message][:user_id]
    	end
      if (session[:email_message][:auth_user_id] && !session[:email_message][:auth_user_id].strip.empty?)
    		  conditions_clause += "and em.auth_user_id = ? "
    	   	conditions_clause_fillins << session[:email_message][:auth_user_id]
    	end
      if (session[:email_message][:cust_id] && !session[:email_message][:cust_id].strip.empty?)
    		  conditions_clause += "and sc.id = ? "
    	   	conditions_clause_fillins << session[:email_message][:cust_id]
    	end
    	if (session[:email_message][:to_address] && !session[:email_message][:to_address].strip.empty?)
      		conditions_clause += "and em.recipient_address like ? "
      		conditions_clause_fillins << (session[:email_message][:to_address] + "%")
    	end
      if ((session[:email_message][:generated_date_start] && !session[:email_message][:generated_date_start].strip.empty?) ||
    	      (session[:email_message][:generated_date_end] && !session[:email_message][:generated_date_end].strip.empty?))
    	  if ((session[:email_message][:generated_date_start] && !session[:email_message][:generated_date_start].strip.empty?) &&
          	    (session[:email_message][:generated_date_end] && !session[:email_message][:generated_date_end].strip.empty?))
              conditions_clause += "and em.generated_date between '#{session[:email_message][:generated_date_start]}' and '#{session[:email_message][:generated_date_end]}'"
        elsif (session[:email_message][:generated_date_start] && !session[:email_message][:generated_date_start].strip.empty?)
            conditions_clause += "and em.generated_date >= '#{session[:email_message][:generated_date_start]}'"
        else
            conditions_clause += "and em.generated_date <= '#{session[:email_message][:generated_date_end]}'"
        end
      end
      if ((session[:email_message][:sent_date_start] && !session[:email_message][:sent_date_start].strip.empty?) ||
    	      (session[:email_message][:sent_date_end] && !session[:email_message][:sent_date_end].strip.empty?))
    	  if ((session[:email_message][:sent_date_start] && !session[:email_message][:sent_date_start].strip.empty?) &&
          	    (session[:email_message][:sent_date_end] && !session[:email_message][:sent_date_end].strip.empty?))
              conditions_clause += "and em.sent_date between '#{session[:email_message][:sent_date_start]}' and '#{session[:email_message][:sent_date_end]}'"
        elsif (session[:email_message][:sent_date_start] && !session[:email_message][:sent_date_start].strip.empty?)
            conditions_clause += "and em.sent_date >= '#{session[:email_message][:sent_date_start]}'"
        else
            conditions_clause += "and em.sent_date <= '#{session[:email_message][:sent_date_end]}'"
        end
      end
      if ((session[:email_message][:ignored_date_start] && !session[:email_message][:ignored_date_start].strip.empty?) ||
    	      (session[:email_message][:ignored_date_end] && !session[:email_message][:ignored_date_end].strip.empty?))
    	  if ((session[:email_message][:ignored_date_start] && !session[:email_message][:ignored_date_start].strip.empty?) &&
          	    (session[:email_message][:ignored_date_end] && !session[:email_message][:ignored_date_end].strip.empty?))
              conditions_clause += "and em.ignored_date between '#{session[:email_message][:ignored_date_start]}' and '#{session[:email_message][:ignored_date_end]}'"
        elsif (session[:email_message][:ignored_date_start] && !session[:email_message][:ignored_date_start].strip.empty?)
            conditions_clause += "and em.ignored_date >= '#{session[:email_message][:ignored_date_start]}'"
        else
            conditions_clause += "and em.ignored_date <= '#{session[:email_message][:ignored_date_end]}'"
        end
      end
    end

    @limit = limit
    if (limit < 0)
      @email_messages = EmailMessage.find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => orders_clause)
    else
      @email_messages = EmailMessage.find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => orders_clause, :limit => limit)
    end
  end
  
  def get_process_messages (sortby, limit)
  case (sortby)
    when "id" then orders_clause = "id asc"
    when "id_desc" then orders_clause = "id desc"
    when "process_type_code" then orders_clause = "process_type_code asc"
    when "process_type_code_desc" then orders_clause = "process_type_code desc"
    when "sam_customer_id" then orders_clause = "sam_customer_id asc"
    when "sam_customer_id_desc" then orders_clause = "sam_customer_id desc"
    when "sam_customer_name" then orders_clause = "sam_customer_name asc"
    when "sam_customer_name_desc" then orders_clause = "sam_customer_name desc"
    when "sam_server_id" then orders_clause = "sam_server_id asc"
    when "sam_server_id_desc" then orders_clause = "sam_server_id desc"
    when "completed_at" then orders_clause = "completed_at asc"
    when "completed_at_desc" then orders_clause = "completed_at desc"
    when "started_at" then orders_clause = "started_at asc"
    when "started_at_desc" then orders_clause = "started_at desc"
    when "pct_complete" then orders_clause = "pct_complete asc"
    when "pct_complete_desc" then orders_clause = "pct_complete desc"
    when "user_email" then orders_clause = "user_id asc"
    when "user_email_desc" then orders_clause = "user_id desc"
      else
        orders_clause = "id"
   end
   
    select_clause = "distinct p.*, sc.id as sam_customer_id, sc.name as sam_customer_name, ss.id as sam_server_id, u.email as user_email "
    joins_clause = "p INNER JOIN process_contexts pc ON p.id=pc.process_id INNER JOIN sam_server ss ON (pc.name='resource' AND pc.value = ss.id) 
                        INNER JOIN sam_customer sc ON ss.sam_customer_id=sc.id LEFT JOIN users u ON p.user_id=u.id "
    conditions_clause = "p.id IS NOT NULL"
    conditions_clause_fillins = []
    
     if (params[:processes])
      session[:processes] = params[:processes]
    end
    if(!params.nil? && params[:process_type]) #don't overwrite session value with a null value
      session[:processes][:process_type] = params[:process_type]
    end  
    
    if (session[:processes][:process_id] && !session[:processes][:process_id].strip.empty?)
        conditions_clause += " AND p.id = ?"
        conditions_clause_fillins << session[:processes][:process_id]
      end
      if (session[:processes][:sam_customer_id] && !session[:processes][:sam_customer_id].strip.empty?)
        conditions_clause += " AND sc.id = ?"
        conditions_clause_fillins << session[:processes][:sam_customer_id]
      end
      if (session[:processes][:server_id] && !session[:processes][:server_id].strip.empty?)
        conditions_clause += " AND ss.id = ?"
        conditions_clause_fillins << session[:processes][:server_id]
      end
      if (session[:processes][:process_type] && !session[:processes][:process_type].empty? && session[:processes][:process_type] == "0" )
      conditions_clause += " AND p.process_type_code = 'SSM'"
      end
      if  (session[:processes][:process_type] && !session[:processes][:process_type].empty? && session[:processes][:process_type] == "1")
        conditions_clause += " AND p.process_type_code = 'SSD'"
      end
      if (session[:processes][:server_type] && !session[:processes][:server_type].empty? && session[:processes][:server_type] == "Hosted" )
      conditions_clause += " AND ss.server_type = '1'"
      end
      if  (session[:processes][:server_type] && !session[:processes][:server_type].empty? && session[:processes][:server_type] == "Local")
        conditions_clause += " AND ss.server_type = '0'"
      end
      if  (session[:processes][:licensing_status] && !session[:processes][:licensing_status].empty? && session[:processes][:licensing_status] == "Yes")
      conditions_clause += " AND sc.licensing_status = 'p' OR sc.licensing_status = 'm' OR sc.licensing_status = 'a'"
      end
      if  (session[:processes][:licensing_status] && !session[:processes][:licensing_status].empty? && session[:processes][:licensing_status] == "No")
        conditions_clause += " AND sc.licensing_status != 'p' AND sc.licensing_status != 'm' AND sc.licensing_status != 'a'"
      end
      if (session[:processes][:completed_by] && !session[:processes][:completed_by].empty? && session[:processes][:completed_by] == "Automated Job")
      conditions_clause += " AND p.user_id IS NULL"
      end
      if (session[:processes][:completed_by] && !session[:processes][:completed_by].empty? && session[:processes][:completed_by] == "User")
        conditions_clause += " AND p.user_id IS NOT NULL"
      end
      if (session[:processes][:process_user_email] && !session[:processes][:process_user_email].strip.empty?)
        conditions_clause += " AND u.email LIKE ?"
        conditions_clause_fillins << ("%" + session[:processes][:process_user_email] + "%")
      end
      if (session[:processes][:process_first_name] && !session[:processes][:process_first_name].strip.empty?)
        conditions_clause += " AND u.first_name = ?"
        conditions_clause_fillins << session[:processes][:process_first_name]
      end
      if (session[:processes][:process_last_name] && !session[:processes][:process_last_name].strip.empty?)
        conditions_clause += " AND u.last_name = ?"
        conditions_clause_fillins << session[:processes][:process_last_name]
      end
      
      if ((session[:processes][:start_date_begin] && !session[:processes][:start_date_begin].strip.empty?) || 
          (session[:processes][:start_date_end] && !session[:processes][:start_date_end].strip.empty?))
      if ((session[:processes][:start_date_begin] && !session[:processes][:start_date_begin].strip.empty?) && 
              (session[:processes][:start_date_end] && !session[:processes][:start_date_end].strip.empty?))
            conditions_clause += "and p.started_at between '#{session[:processes][:start_date_begin]}' and '#{session[:processes][:start_date_end]}'"
      end
      end
    
    

    @limit = limit
    if (limit < 0)
      @processes = SamcProcess.find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => orders_clause)
    else
      @processes = SamcProcess.find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => orders_clause, :limit => limit)
    end
  end
  
   def get_orgs(sortby, limit)
    case (sortby) #mapping all column view names to database fields here to keep view seperate from model
      when "UCN" then orders_clause = "ucn"
      when "UCN desc" then orders_clause = "ucn desc"
      when "organization_name" then orders_clause = "org_name"
      when "organization_name desc" then orders_clause = "org_name desc"
      when "city" then orders_clause = "city_name"
      when "city desc" then orders_clause = "city_name desc"
      when "state" then orders_clause = "state_name"
      when "state desc" then orders_clause = "state_name desc"
      when "postal_code" then orders_clause = "postal_code"
      when "postal_code desc" then orders_clause = "postal_code desc"
      when "status" then orders_clause = "status_description"
      when "status desc" then orders_clause = "status_description desc"
      when "group" then orders_clause = "group_description"
      when "group desc" then orders_clause = "group_description desc"
      when "type" then orders_clause = "type_description"
      when "type desc" then orders_clause = "type_description desc"
      when SAM_CUSTOMER_TERM then orders_clause = "sam_customer_id"
      when (SAM_CUSTOMER_TERM+" desc") then orders_clause = "sam_customer_id desc"
      when "child_count" then orders_clause = "number_of_children"
      when "child_count desc" then orders_clause = "number_of_children desc"
      else orders_clause = sortby #shouldn't be reached
    end
  
    #put whole array from search form into session
    #when a resubmit comes in from the user sorting the list, :org will not be included in the request
    logger.debug("UCN PARAMS"+params[:org][:ucn])
    if (params[:org])
      session[:org] = params[:org]
      session[:org].each_pair {|k,v| v.strip!}
    end
  
    @limit = limit
    @orgs = Org.search(session[:org], limit, orders_clause)
  end

 def get_tasks(sortby, limit)
    case (sortby) #mapping all column view names to database fields here to keep view seperate from model
      when "id" then orders_clause = "id"
      when "id desc" then orders_clause = "id desc"
      when "type" then orders_clause = "task_type_description"
      when "type desc" then orders_clause = "task_type_description desc"
      when "status" then orders_clause = "status"
      when "status desc" then orders_clause = "status desc"
      when "comment" then orders_clause = "comment"
      when "comment desc" then orders_clause = "comment desc"
      when "created_at" then orders_clause = "task_created_at"
      when "created_at desc" then orders_clause = "task_created_at desc"
      when "closed_at" then orders_clause = "task_closed_at"
      when "closed_at desc" then orders_clause = "task_closed_at desc"
      when "closed_by" then orders_clause = "closed_by_first_name"
      when "closed_by desc" then orders_clause = "closed_by_first_name desc"
      when "tms_entitlementid" then orders_clause = "tms_entitlementid"
      when "tms_entitlementid desc" then orders_clause = "tms_entitlementid desc"
      when PRODUCT_TERM then orders_clause = "product_description"
      when (PRODUCT_TERM+" desc") then orders_clause = "product_description desc"
      when "license_count" then orders_clause = "license_count"
      when "license_count desc" then orders_clause = "license_count desc"
      when "order_num" then orders_clause = "order_num"
      when "order_num desc" then orders_clause = "order_num desc"
      when "invoice_num" then orders_clause = "invoice_num"
      when "invoice_num desc" then orders_clause = "invoice_num desc"
      when SAM_CUSTOMER_TERM then orders_clause = "sam_customer_name"
      when (SAM_CUSTOMER_TERM+" desc") then orders_clause = "sam_customer_name desc"
      when "state" then orders_clause = "state_name"
      when "state desc" then orders_clause = "state_name desc"
      else orders_clause = sortby #shouldn't be reached
    end
  
    #put whole array from search form into session
    #when a resubmit comes in from the user sorting the list, :task will not be included in the request
    if (params[:task])
      session[:task] = params[:task]
    end
    
    #these are also only passsed in the request from the initial search form, outside of the :task array
    session[:task][:task_created_at_start_date] = params[:task_created_at_start_date] || "" #always set a session value to avoid null reference, default to empty string as necesary
    session[:task][:task_created_at_end_date] = params[:task_created_at_end_date] || ""
    session[:task][:task_closed_start_date] = params[:task_closed_start_date] || ""
    session[:task][:task_closed_end_date] = params[:task_closed_end_date] || ""
    
    #puts "params[:task]: #{params[:task].to_yaml}"
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
    
    @limit = limit
    @tasks = Task.search(session[:task], limit, orders_clause)
  end


  def get_entitlement_reference_info
    @product_type_list = [["-any-", nil]].concat(Product.find(:all, :order => "description").collect {|p| [p.description, p.id]})
    @product_group_list = [["-any-", nil]].concat(ProductGroup.find(:all, :order => "description").collect {|pg| [pg.description, pg.id]})
    @order_type_list = [["-any-", nil]].concat(OrderType.find(:all, :order => "description").collect {|et| [et.description, et.id]})
    @sc_entitlement_type_list = [["-any-", nil]].concat(ScEntitlementType.find(:all, :order => "description").collect {|et| [et.description, et.id]})

  end

  def get_org_reference_info
    individual_type = CustomerType.find_by_code(CustomerType.INDIVIDUAL_CODE)
    @customer_status_list = [["-any-", nil]].concat(CustomerStatus.find(:all, :order => "description").collect {|cs| [cs.description, cs.description]})
    @customer_group_list = [["-any-", nil], ["District", "D"], ["School", "S"]]
    @customer_type_list = [["-any-", nil]].concat(CustomerType.find(:all, :conditions => ["id != ?", individual_type.id], :order => "description").collect {|ct| [ct.description, ct.id]})
  end

  def get_task_reference_info
    conditions_clause_str = ""
    conditions_clause_str += "user_type = 's'" if (current_user != User.TYPE_SCHOLASTIC)
    @task_type_list = [["-any-", nil]].concat(TaskType.find(:all, :conditions => conditions_clause_str, :order => "description").collect {|tt| [tt.description, tt.id]})
    @user_list = [["-any-", nil]].concat(User.find(:all, :conditions => ["active = true and user_type != ?", User.TYPE_CUSTOMER], :order => "last_name").collect {|u| [u.first_name + " " + u.last_name, u.id] })
    @task_status_list = [["-any-", nil], ["Assigned", "a"], ["Closed", "c"], ["Unassigned", "u"]]
  end

  def get_sam_customer_reference_info
    @community_list = [["-any-", nil]].concat(Community.find(:all, :order => "name").collect{|c| [c.name, c.id]})
  end

  def get_email_type_reference_info
    @email_type_list = [["-any-", nil]].concat(EmailType.find(:all, :order => "description").collect{|et| [et.description, et.id]})
  end

  def get_auth_user_type_reference_info
    @auth_user_type_list = [["-any-", nil]].concat(AuthUser.find(:all, :select => "DISTINCT type AS auth_user_type", :order => "type ASC").collect{|aut| [aut.auth_user_type]}) #have to alias type AS auth_user_type because type is a reserved ActiveRecord word
  end

  def load_view_support_libraries
    @date_selector_support = true
  end

  def get_agent_plugins_info
    @agent_plugins_list = [["-any-", nil]].concat(AgentPlugin.find(:all, :select => "DISTINCT name AS plugin_name").collect{|ap| [ap.plugin_name, ap.plugin_name]})
  end

  
end
