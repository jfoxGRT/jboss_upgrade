require "csv"
require "date"

begin
  import 'sami.web.SC'
  import 'java.util.HashSet'
  import 'java.util.HashMap'
  import 'java.util.ArrayList'
  import 'java.lang.Integer'
  import 'java.lang.Boolean'
  import 'sami.scholastic.api.process.resource_transfer.ResourceTransferPackage'
  import 'sami.scholastic.api.process.OrderLinePackage'
  import 'sami.scholastic.api.process.SamcProcessPackage'
  import 'sami.scholastic.api.process.resource_transfer.ServerDeactivatorPackage'
  import 'java.util.GregorianCalendar'

rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
require 'fastercsv'

class UtilitiesController < ApplicationController
  include WebAPIShared
  layout "default_with_utilities_subtabs"
  def playground
    config_sam_customer_pi_chart

    #@state_sam_customer_counts = SamCustomer.count_by_us_state_province
    @sam_customer = SamCustomer.new
    country_id = Country.find_by_code("US").id
    @state_provinces = StateProvince.find(:all, :conditions => ["country_id = ?", country_id])
    #@map_data_json = SamCustomer.find_registered.to_json()
    #render(:layout => "jquery_and_yahoo_maps")
    @button_support = true
    @widget_list << Widget.new("lm_data", "License Manager", nil, 600, 700)
    @widget_list << Widget.new("global_data", "Global Data", nil, 600, 700)
    @widget_list << Widget.new("am_data", "Authentication Data", nil, 600, 700)
    #config_sam_customer_pi_chart
    config_sam_server_line_chart
    @prototype_required = true
    config_sam_customer_line_chart
    render(:layout => "default_with_docking")
  end

  def playground2
    #config_sam_customer_pi_chart
    config_sam_server_line_chart

    config_sam_customer_line_chart
    render(:layout => "default_with_docking")
  end

  def playground3
    render(:layout => "default_with_docking")
  end

  def lm_data_ooc
    render(:text => "Coming soon!")
  end

  def lm_data_converted_licenses
    render(:text => "Coming soon!")
  end

  def am_data_disabled_auth_users
    @disabled_auth_users = SamCustomer.find(:all, :select => "distinct sc.*, c.ucn, count(au.id) as num_disabled_auth_users",
    :joins => "sc inner join auth_user au on au.sam_customer_id = sc.id
                                        inner join org on sc.root_org_id = org.id
                                        inner join customer c on org.customer_id = c.id
                                        inner join sam_server_user ssu on ssu.auth_user_id = au.id",
    :conditions => "au.enabled = false",
    :group => "sc.id", :order => "sc.name")
    render(:partial => "am_data_disabled_auth_users", :locals => {:disabled_auth_users => @disabled_auth_users})
  end

  def am_data_orphaned_auth_users
    @orphaned_auth_users = SamCustomer.find(:all, :select => "distinct sc.*, c.ucn, count(au.id) as num_orphaned_auth_users",
    :joins => "sc inner join auth_user au on au.sam_customer_id = sc.id
                                        inner join org on sc.root_org_id = org.id
                                        inner join customer c on org.customer_id = c.id
                                        left join sam_server_user ssu on ssu.auth_user_id = au.id",
    :conditions => "ssu.id is null and au.enabled = true",
    :group => "sc.id", :order => "sc.name")
    render(:partial => "am_data_orphaned_auth_users", :locals => {:orphaned_auth_users => @orphaned_auth_users})
  end

  def global_data_cloned_servers
    @cloned_servers = SamCustomer.find(:all, :select => "distinct sc.*, c.ucn, count(ss.id) as num_cloned_servers",
    :joins => "sc inner join sam_server ss on ss.sam_customer_id = sc.id
                                        inner join org on sc.root_org_id = org.id
                                        inner join customer c on org.customer_id = c.id",
    :conditions => ["ss.clone_parent_id is not null and ss.status = 'a'"],
    :group => "sc.id", :order => "sc.name")
    render(:partial => "global_data_cloned_servers", :locals => {:cloned_servers => @cloned_servers})
  end

  def global_data_hosted_customers
    @hosted_customers = SamCustomer.find(:all, :select => "distinct sc.*, c.ucn",
    :joins => "sc inner join sam_server ss on ss.sam_customer_id = sc.id
                                    inner join org on sc.root_org_id = org.id
                                    inner join customer c on org.customer_id = c.id",
    :conditions => ["ss.server_type = ? and ss.status = 'a' and sc.active = true", SamServer::TYPE_HOSTED],
    :order => "sc.name")
    render(:partial => "global_data_hosted_customers", :locals => {:hosted_customers => @hosted_customers})
  end

  def global_data_unmatched_schools
    @unmatched_schools = SamCustomer.find(:all, :select => "distinct sc.*, c.ucn, count(sssi.id) as num_unmatched_schools",
    :joins => "sc inner join sam_server ss on ss.sam_customer_id = sc.id
                                    inner join org on sc.root_org_id = org.id
                                    inner join customer c on org.customer_id = c.id
                                    inner join sam_server_school_info sssi on sssi.sam_server_id = ss.id",
    :conditions => "sssi.org_id is null and ss.status = 'a'",
    :group => "sc.id", :order => "sc.name")
    render(:partial => "global_data_unmatched_schools", :locals => {:unmatched_schools => @unmatched_schools})
  end

  def global_data_logged_in_users
    @users = User.find_currently_logged_in
    render(:partial => "global_data_logged_in_users", :object => @users)
  end

  def sam_customer_operations
    redirect_to(:controller => :home) if (@current_user.isScholasticType)
    @prototype_required = true
  end

  def test_progress_bar
    render(:layout => "jquery_ui_and_progress_bar")
  end

  def index
    if current_user.hasScholasticPermission(Permission.utilities_qa_functions)
      redirect_to :controller => :utilities, :action => :qa_functions
    else
      redirect_to :controller => :utilities, :action => :reports
    end
  end

  def qa_functions
  end

  def op_functions
    process_types = SamcProcess.find_counts_by_process_type
    @process_type_hash = {}
    process_types.each do |pt|
      if @process_type_hash[pt.process_type_code].nil?
        @process_type_hash[pt.process_type_code] = []
        @process_type_hash[pt.process_type_code] << 0 if (pt.complete == 1)
      end
      @process_type_hash[pt.process_type_code] << pt.the_count
    end
    @db_processes = SamCustomer.find_by_sql('show processlist')
    @prototype_required = true
  end

  def update_db_processlist
    @db_processes = SamCustomer.find_by_sql('show processlist')
    render(:partial => "db_processlist", :locals => {:db_processes => @db_processes})
  end

  def cust_maint_functions
  end

  def adjust_virtuals
    render(:layout => "default_with_utilities_subtabs", :partial => "adjust_virtuals")
  end

  def license_counts_for_ucn
    @ucn = params[:ucn]
    @org = Customer.find_details_by_ucn(params[:ucn].to_i)
    if (@org)
      @sam_customer = @org.sam_customer_id ? SamCustomer.find(@org.sam_customer_id) : nil
      if (@sam_customer)
        @custom_license_table = SamCustomer.find_by_sql("
select
  s.id as subcommunity_id,
  s.name as subcommunity_name,
  sp.id as unallocated_pool_id,
  sp.seat_count as unallocated_count,
  (select
    sum(e.license_count)
  from
    entitlement e inner join product p on e.product_id = p.id
    inner join subcommunity  s1 on s1.product_id = p.id
    where
      s1.id = s.id and
      e.sc_entitlement_type_id = 4 and
      e.sam_customer_id = " + @sam_customer.id.to_s + "
  ) as virtual_count
from
  seat_pool sp inner join subcommunity s on (sp.subcommunity_id = s.id and sp.sam_server_id is null)
where
  sp.sam_customer_id = " + @sam_customer.id.to_s)

        #@license_count_comparisons, @resyncable = @sam_customer.build_seat_count_profile(nil, nil)
      else
        flash[:notice] = "The UCN you entered is not a SAM EE Customer."
      end
    else
      flash[:notice] = "The UCN you entered does not exist."
    end
    render(:layout => "default_with_utilities_subtabs", :partial => "adjust_virtuals", :locals => {:custom_license_table => @custom_license_table})
    return
  end

  def really_adjust_virtuals
    message = ""
    params.each_key do |k|
      if (!k.index("delta_").nil? && k.index("delta_") == 0)
        seat_pool_id = k.slice(6, k.size).to_i
        delta = params[k].to_i
        logger.info("seat pool id : #{seat_pool_id}")
        logger.info("delta : #{delta}")
        if (delta != 0)
          logger.info("Take action here only")
          seat_pool = SeatPool.find(seat_pool_id)
          # TODO: make sure that the seat count hasn't changed since!
          seat_pool_service = SC.getBean("seatPoolService")
          if (seat_pool_service.adjustTotalLicenses(seat_pool_id, delta, current_user.id, "Virtual license adjustor tool"))
            message << "Successfully applied #{delta} licenses for #{seat_pool.subcommunity.name}." << "<br>"
          else
            message << "Could not apply #{delta} licenses for #{seat_pool.subcommunity.name}.  Please check the delta and try again." << "<br>"
          end
        end
      end
    end
    if (message != "")
      flash[:notice] = message
      flash[:msg_type] = "info"
    end
    redirect_to :action => :license_counts_for_ucn, :ucn => params[:hidden_ucn]
    return
  end

  def reports
  end

  def reference_data

  end

  def processes
    completed_at_clause = (params[:complete] == "1") ? "p.completed_at is not null" : "p.completed_at is null"
    @processes = SamcProcess.find(:all, :select => "p.*, u.email", :joins => "p left join users u on p.user_id = u.id", :conditions => ["p.process_type_code = ? and #{completed_at_clause}",params[:id]], :order => "p.id desc")
  end

  def process_details
    @process = SamcProcess.find(params[:id])
    @process_contexts = @process.process_contexts
    @process_message_responses = ProcessMessageResponse.find(:all, :select => "pmr.*", :joins => "pmr inner join process_messages pm on pmr.process_message_id = pm.id", :conditions => ["pm.process_id = ?", @process.id],
    :order => "pmr.id desc")
  end

  def interrupt_process_message_response
    pmr = ProcessMessageResponse.find(params[:id])
    pmr.update_attribute(:completed_at, Time.now)
    render(:text => Time.now.strftime(DATE_FORM))
  end

  def interrupt_process
    process = SamcProcess.find(params[:id])
    process.update_attribute(:completed_at, Time.now)
    process_message_responses = ProcessMessageResponse.find(:all, :select => "pmr.*", :joins => "pmr inner join process_messages pm on pmr.process_message_id = pm.id", :conditions => ["pm.process_id = ?", process.id])
    process_message_responses.each do |pmr|
      pmr.update_attribute(:completed_at, Time.now)
    end
    render(:text => Time.now.strftime(DATE_FORM))
  end

  ###
  ### START of "Utilities -> Reports" methods
  ###

  # Reports - Unmatched Schools

  def unmatched_schools
    params[:sort] ||= "cust_name"
    @sort_order = params[:sort]
#    @unmatched_schools = get_unmatched_schools("0", @sort_order)
    @unmatched_schools = find_unmatched_schools("0", @sort_order)
    @num_rows_reported = @unmatched_schools.length
    render(:layout => "cs_blank_layout")
  end

  def export_unmatched_schools_to_csv
    logger.info "EXPORTING CSV"
#    @unmatched_schools_results = get_unmatched_schools("0", "cust_name")
    @unmatched_schools_results = find_unmatched_schools("0", "cust_name")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Customer Name", "Customer ID", "UCN", "Server Name", "Server ID", "School Name", "School ID", "School Address", "City", "State", "Zip"]
      @unmatched_schools_results.each do |school|
        # data row
        csv_row << [school.customer_name, school.customer_id, school.ucn, school.server_name, school.server_id, school.school_name, school.school_id, school["address1"], school["city"], school["state"], school["postal_code"]]
      end
    end
    file_name = "unmatched_schools_nonhosted.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  def unmatched_schools_hosted
    params[:sort] ||= "cust_name"
    @sort_order = params[:sort]
#    @unmatched_schools_hosted = get_unmatched_schools("1", @sort_order)
    @unmatched_schools_hosted = find_unmatched_schools("1", @sort_order)
    @num_rows_reported = @unmatched_schools_hosted.length
    render(:layout => "cs_blank_layout")
  end

  def export_unmatched_schools_hosted_to_csv
    logger.info "EXPORTING CSV"
#    @unmatched_schools_hosted_results = get_unmatched_schools("1", "cust_name")
    @unmatched_schools_hosted_results = find_unmatched_schools("1", "cust_name")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Customer Name", "Customer ID", "UCN", "Server Name", "Server ID", "School Name", "School ID", "School Address", "City", "State", "Zip"]
      @unmatched_schools_hosted_results.each do |school|
        # data row
        csv_row << [school.customer_name, school.customer_id, school.ucn, school.server_name, school.server_id, school.school_name, school.school_id, school["address1"], school["city"], school["state"], school["postal_code"]]
      end
    end
    file_name = "unmatched_schools_hosted.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  def find_unmatched_schools(servertype, sortby)
	  logger.debug "Calling find_unmatched_schools"
	  payload = {
	    :method_name => 'unmatched_schools',
	    :server_type => servertype,
	    :sort_by => sortby		
	  }
      response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
              payload,
              CustServServicesHandler::ROUTES['utilities_web_services'])

      puts response.body
      parsed_json = ActiveSupport::JSON.decode(response.body)
	  @unmatched_schools = []
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
		  parsed_json["unmatched_schools"].each do |e| 
		  ss = SamServer.new
				  parsed_json_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(e))
				  parsed_json_row.each {|k,v|
			  ss[k.to_sym] = v
		  }
		  @unmatched_schools << ss
		  end
	  end	  
			
	@ret_customers = @unmatched_schools

end  
  
  def get_unmatched_schools(server_type, sortby)
    case (sortby)
    when "server_id" then orders_clause = "ss.id"
    when "server_id_desc" then orders_clause = "ss.id desc"
    when "server_name" then orders_clause = "ss.name"
    when "server_name_desc" then orders_clause = "ss.name desc"
    when "cust_id" then orders_clause = "sc.id"
    when "cust_id_desc" then orders_clause = "sc.id desc"
    when "cust_name" then orders_clause = "sc.name"
    when "cust_name_desc" then orders_clause = "sc.name desc"
    when "ucn" then orders_clause = "c.ucn"
    when "ucn_desc" then orders_clause = "c.ucn desc"
    when "school_id" then orders_clause = "sssi.id"
    when "school_id_desc" then orders_clause = "sssi.id desc"
    when "school_name" then orders_clause = "sssi.name"
    when "school_name_desc" then orders_clause = "sssi.name desc"
    when "address1" then orders_clause = "sssi.address1"
    when "address1_desc" then orders_clause = "sssi.address1 desc"
    when "city" then orders_clause = "sssi.city"
    when "city_desc" then orders_clause = "sssi.city desc"
    when "state" then orders_clause = "sssi.state"
    when "state_desc" then orders_clause = "sssi.state desc"
    when "zip" then orders_clause = "sssi.postal_code"
    when "zip_desc" then orders_clause = "sssi.postal_code desc"
    else orders_clause = "sc.name"
    end
    puts orders_clause
    SamServer.find_by_sql("select ss.id as server_id, ss.name as server_name, sc.id as customer_id, sc.name as customer_name,
      c.ucn as ucn, sssi.id as school_id, sssi.name as school_name, sssi.address1 as address1, sssi.city as city, sssi.state as state, sssi.postal_code as postal_code
      from sam_customer sc, sam_server ss, sam_server_school_info sssi, org o, customer c
	  where ss.sam_customer_id = sc.id and ss.server_type = " + server_type + " and ss.status in ('a','t') and sssi.sam_server_id = ss.id and sssi.status = 'n' and o.customer_id = c.id and o.id = sc.root_org_id and sc.fake = 0
	  order by " + orders_clause )
  end

  # Report - Customer Registrations

  def customer_registration
    params[:sort] ||= "num_servers_desc"
    @sort_order = params[:sort]
    @customer_registrations = find_customer_registrations(@sort_order)
    @num_rows_reported = @customer_registrations.length
    render(:layout => "cs_blank_layout")
  end
  
  def find_customer_registrations(sortby)
  logger.debug "Calling find_customer_registrations"
  payload = {
    :method_name => 'customer_registrations',
    :sort_by => sortby		
  }
      response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
              payload,
              CustServServicesHandler::ROUTES['utilities_web_services'])

      puts response.body
      parsed_json = ActiveSupport::JSON.decode(response.body)
	  @customer_registrations = []
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
		  parsed_json["customer_registrations"].each do |e| 
		  report_records = Hash.new
				  parsed_json_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(e))
				  parsed_json_row.each {|k,v|
			  report_records[k.to_sym] = v
		  }
		  @customer_registrations << report_records
		  end
	  end	  
			
	@ret_customers = @customer_registrations

end  

  def get_customer_registrations(sortby)
    case (sortby)
    when "customer" then orders_clause = "sc.name"
    when "customer_desc" then orders_clause = "sc.name desc"
    when "customer_id" then orders_clause = "sc.id"
    when "customer_id_desc" then orders_clause = "sc.id desc"
    when "state" then orders_clause = "state"
    when "state_desc" then orders_clause = "state desc"
    when "num_servers" then orders_clause = "num_servers"
    when "num_servers_desc" then orders_clause = "num_servers desc"
    when "earliest_reg" then orders_clause = "earliest_reg"
    when "earliest_reg_desc" then orders_clause = "earliest_reg desc"
    when "latest_reg" then orders_clause = "latest_reg"
    when "latest_reg_desc" then orders_clause = "latest_reg desc"
    when "lm_activated" then orders_clause = "lm_activated"
    when "lm_activated_desc" then orders_clause = "lm_activated desc"
    when "lm_activated_date" then orders_clause = "lm_activated_date"
    when "lm_activated_date_desc" then orders_clause = "lm_activated_date desc"
    when "um_activated" then orders_clause = "um_activated"
    when "um_activated_desc" then orders_clause = "um_activated desc"
    when "um_activated_date" then orders_clause = "um_activated_date"
    when "um_activated_date_desc" then orders_clause = "um_activated_date desc"
    when "school_count" then orders_clause = "school_count"
    when "school_count_desc" then orders_clause = "school_count desc"
    when "ucn" then orders_clause = "ucn"
    when "ucn_desc" then orders_clause = "ucn desc"
    when "sc_admin_exists" then orders_clause = "sc_admin_exists"
    when "sc_admin_exists_desc" then orders_clause = "sc_admin_exists desc"
    else orders_clause = "num_servers desc"
    end
    SamServer.find_by_sql("select distinct sc.name as customer, sc.id as customer_id,
      (select distinct sp.code from org o, customer c, customer_address ca, address_type at, state_province sp where ss.sam_customer_id = sc.id and sc.root_org_id = o.id and o.customer_id = c.id and c.id = ca.customer_id and ca.state_province_id = sp.id and ca.address_type_id = 5) as state,
      count(ss.id) as num_servers,
      min(ss.created_at) as earliest_reg,
      max(ss.created_at) as latest_reg,
      if (sc.sc_licensing_activated IS NULL, 'N', 'Y') as 'lm_activated',
      sc.sc_licensing_activated as 'lm_activated_date',
      if (sc.update_manager_activated IS NULL, 'N', 'Y') as 'um_activated',
      sc.update_manager_activated as 'um_activated_date',
      (select count(distinct sssi.org_id) from sam_server ss1, sam_server_school_info sssi where ss1.sam_customer_id = sc.id and ss1.status = 'a' and sssi.sam_server_id = ss1.id and sssi.fake = 0 and sssi.org_id is not null) as school_count,
      (select distinct c.ucn from org o, customer c where ss.sam_customer_id = sc.id and sc.root_org_id = o.id and o.customer_id = c.id) as ucn,
      if ( (select count(*) from users u where u.active and u.sam_customer_id = sc.id and u.id in (select user_id from user_permission where permission_id = 1) > 0), 'Y', 'N') as 'sc_admin_exists'
      from
      sam_server ss, sam_customer sc
      where
      ss.sam_customer_id = sc.id and
      ss.status != 'i' and
      ss.server_type != 2 and
      NOT sc.fake 
      group by sc.id order by " + orders_clause)
  end

  def export_customer_registration_to_csv
    logger.info "EXPORTING CSV"
    @customer_registration_results = get_customer_registrations("num_servers_desc")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["SAM Customer Name", "SC ID", "State", "Number of Servers", "Earliest Registration", "Latest Registration", "LM Activated?", "LM Activated Date", "UM Activated", "UM Activated Date?", "School Count", "UCN", "SC Admin Exists?"]
      @customer_registration_results.each do |customer|
        # data row
        csv_row << [customer.customer, customer.customer_id, customer.state, customer.num_servers, customer.earliest_reg, customer.latest_reg, customer.lm_activated, customer.lm_activated_date, customer.um_activated, customer.um_activated_date, customer.school_count, customer.ucn, customer.sc_admin_exists]
      end
    end
    file_name = "customer_registration.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  # Report - Server Registration

  def server_registration
    params[:sort] ||= "day_desc"
    @sort_order = params[:sort]
    @server_registrations = get_server_registrations(@sort_order)
    @num_rows_reported = @server_registrations.length
    render(:layout => "cs_blank_layout")
  end

  def export_server_registration_to_csv
    logger.info "EXPORTING CSV"
    @server_registration_results = get_server_registrations("day_desc")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Day", "Registration Count"]
      @server_registration_results.each do |server|
        # data row
        csv_row << [server.day, server.registration_count]
      end
    end
    file_name = "server_registration.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  def get_server_registrations(sortby)
    case (sortby)
    when "day" then orders_clause = "day"
    when "day_desc" then orders_clause = "day desc"
    when "registration_count" then orders_clause = "registration_count"
    when "registration_count_desc" then orders_clause = "registration_count desc"
    else orders_clause = "day desc"
    end
    SamServer.find_by_sql("select substr(ss.created_at, 1, 10) as day,
      count(1) as registration_count
      from sam_server ss, sam_customer sc
      where ss.sam_customer_id = sc.id and ss.status = 'a' and sc.fake = 0
      and ss.name NOT LIKE '%_UNREGISTERED_%'
      group by day order by " + orders_clause)
  end

  # Report - Deactivated Servers

  def deactivated_servers
    params[:sort] ||= "cust_name"
    @sort_order = params[:sort]
#    @deactivated_servers = get_deactivated_servers(@sort_order)
    @deactivated_servers = find_deactivated_servers(@sort_order)
    @num_rows_reported = @deactivated_servers.length
    render(:layout => "cs_blank_layout")
  end
  
  def find_deactivated_servers(sortby)
  logger.debug "Calling find_deactivated_servers"
  payload = {
    :method_name => 'deactivated_servers',
    :sort_by => sortby		
  }
      response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
              payload,
              CustServServicesHandler::ROUTES['utilities_web_services'])

      puts response.body
      parsed_json = ActiveSupport::JSON.decode(response.body)
	  @deactivated_servers = []
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
		  parsed_json["deactivated_servers"].each do |e| 
		  ss = SamServer.new
				  parsed_json_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(e))
				  parsed_json_row.each {|k,v|
			  ss[k.to_sym] = v.gsub("[bs]", '\\')
		  }
		  @deactivated_servers << ss
		  end
	  end	  
			
	@ret_customers = @deactivated_servers

end

  def get_deactivated_servers(sortby)
    case (sortby)
    when "cust_name" then orders_clause = "sc.name"
    when "cust_name_desc" then orders_clause = "sc.name desc"
    when "cust_id" then orders_clause = "cust_id"
    when "cust_id_desc" then orders_clause = "cust_id desc"
    when "server_id" then orders_clause = "ss.id"
    when "server_id_desc" then orders_clause = "ss.id desc"
    when "server_name" then orders_clause = "ss.name"
    when "server_name_desc" then orders_clause = "ss.name desc"
    when "server_registration" then orders_clause = "ss.created_at"
    when "server_registration_desc" then orders_clause = "ss.created_at desc"
    when "server_active" then orders_clause = "ss.status"
    when "server_active_desc" then orders_clause = "ss.status desc"
    when "agent_id" then orders_clause = "a.id"
    when "agent_id_desc" then orders_clause = "a.id desc"
    when "agent_last_connected" then orders_clause = "a.updated_at"
    when "agent_last_connected_desc" then orders_clause = "a.updated_at desc"
    else orders_clause = "sc.name"
    end
    SamServer.find_by_sql("select ss.id as server_id, ss.name as server_name,
      ss.sam_customer_id as cust_id, sc.name as cust_name,
      if ((ss.status = 'a'), 'Y', 'N') as server_active,
      ss.created_at as server_registration_date,
      a.id as agent_id, a.updated_at as agent_last_connected
      from sam_server ss
        inner join sam_customer sc on ss.sam_customer_id = sc.id
        left join agent a on ss.id = a.sam_server_id
      where ss.status = 'i' and sc.fake = 0
      order by " + orders_clause)
  end

  def export_deactivated_servers_to_csv
    logger.info "EXPORTING CSV"
#    @deactivated_servers_results = get_deactivated_servers("cust_name")
    @deactivated_servers_results = find_deactivated_servers("cust_name")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Customer Name", "Customer ID", "Server Name", "Server ID", "Server Active", "Server Registration Date", "Agent ID", "Agent Last Connected"]
      @deactivated_servers_results.each do |server|
        # data row
        csv_row << [server.cust_name, server.cust_id, server.server_name, server["server_id"], server.server_active, server.server_registration_date, server["agent_id"], server["agent_last_connected"]]
      end
    end
    file_name = "deactivated_servers.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  # Report - SRC Quiz Updates

  def src_quiz_updates
    params[:sort] ||= "cust_name"
    @sort_order = params[:sort]
#    @src_quiz_updates = get_src_quiz_updates(@sort_order)
    @src_quiz_updates = find_src_quiz_updates(@sort_order)
    @num_rows_reported = @src_quiz_updates.length
    render(:layout => "cs_blank_layout")
  end

  
  def find_src_quiz_updates(sortby)
	  logger.debug "Calling find_src_quiz_updates"
	  payload = {
	    :method_name => 'src_quiz_updates',
	    :sort_by => sortby		
	  }
      response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
              payload,
              CustServServicesHandler::ROUTES['utilities_web_services'])

      logger.debug "Response:" + response.body
      parsed_json = ActiveSupport::JSON.decode(response.body)
	  @src_quiz_updates = []
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
		  parsed_json["src_quiz_updates"].each do |e| 
		  ss = SamServer.new
				  parsed_json_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(e))
				  parsed_json_row.each {|k,v|
			  ss[k.to_sym] = v
		  }
		  @src_quiz_updates << ss
		  end
	  end	  
				
		@ret_customers = @src_quiz_updates

	end

  
  
  def get_src_quiz_updates(sortby)
    case (sortby)
    when "cust_name" then orders_clause = "sc.name"
    when "cust_name_desc" then orders_clause = "sc.name desc"
    when "cust_id" then orders_clause = "cust_id"
    when "cust_id_desc" then orders_clause = "cust_id desc"
    when "ucn" then orders_clause = "c.ucn"
    when "ucn_desc" then orders_clause = "c.ucn desc"
    when "server_name" then orders_clause = "ss.name"
    when "server_name_desc" then orders_clause = "ss.name desc"
    when "server_id" then orders_clause = "ss.id"
    when "server_id_desc" then orders_clause = "ss.id desc"
    when "last_applied_at" then orders_clause = "last_applied_at"
    when "last_applied_at_desc" then orders_clause = "last_applied_at desc"
    when "last_applied_quiz" then orders_clause = "last_applied_quiz"
    when "last_applied_quiz_desc" then orders_clause = "last_applied_quiz desc"
    else orders_clause = "sc.name"
    end
    SamServer.find_by_sql("select distinct sc.id as cust_id, sc.name as cust_name, c.ucn as ucn,
        ss.id as server_id, ss.name as server_name, max(completed_at) as last_applied_at,
		max(managed_component_target_version) as last_applied_quiz
      from sam_customer sc, sam_server ss, server_scheduled_update_request ssur, org o, customer c
	  where ssur.sam_server_id = ss.id and ss.sam_customer_id = sc.id and ssur.completed_at is not null and
        ssur.managed_component_code like '%srcquiz%' and ssur.created_at > '2010-03-01 12:00:00' and
        o.customer_id = c.id and o.id = sc.root_org_id
	  group by ss.id
	  order by " + orders_clause)
  end

  def export_src_quiz_updates_to_csv
    logger.info "EXPORTING CSV"
#    @src_quiz_updates_results = get_src_quiz_updates("cust_name")
    @src_quiz_updates_results = find_src_quiz_updates("cust_name")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["SAM Customer Name", "SC ID", "UCN", "Server Name", "Server ID", "Last Applied At", "Last Applied Quiz"]
      @src_quiz_updates_results.each do |server|
        # data row
        csv_row << [server.cust_name, server.cust_id, server.ucn, server.server_name, server.server_id, server["last_applied_at"], server["last_applied_quiz"]]
      end
    end
    file_name = "src_quiz_updates.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  # Report - Corrected Clones

  def corrected_clones
    params[:sort] ||= "clone_created_at_desc"
    @sort_order = params[:sort]
    @corrected_clones = get_corrected_clones(@sort_order)
    @num_rows_reported = @corrected_clones.length
    render(:layout => "cs_blank_layout")
  end

  def get_corrected_clones(sortby)
    case (sortby)
    when "clone_id" then orders_clause = "ss.id"
    when "clone_id_desc" then orders_clause = "ss.id desc"
    when "clone_name" then orders_clause = "ss.name"
    when "clone_name_desc" then orders_clause = "ss.name desc"
    when "clone_status" then orders_clause = "ss.status"
    when "clone_status_desc" then orders_clause = "ss.status desc"
    when "clone_created_at" then orders_clause = "ss.created_at"
    when "clone_created_at_desc" then orders_clause = "ss.created_at desc"
    when "cust_name" then orders_clause = "sc.name"
    when "cust_name_desc" then orders_clause = "sc.name desc"
    when "cust_id" then orders_clause = "sc.id"
    when "cust_id_desc" then orders_clause = "sc.id desc"
    when "parent_id" then orders_clause = "parent_id"
    when "parent_id_desc" then orders_clause = "parent_id desc"
    when "parent_name" then orders_clause = "parent_name"
    when "parent_name_desc" then orders_clause = "parent_name desc"
    when "parent_status" then orders_clause = "parent_status"
    when "parent_status_desc" then orders_clause = "parent_status desc"
    when "parent_created_at" then orders_clause = "parent_created_at"
    when "parent_created_at_desc" then orders_clause = "parent_created_at desc"
    else orders_clause = "sc.name"
    end
    SamServer.find_by_sql("select ss.id as clone_id, ss.name as clone_name,
      ss.status, ss.created_at as clone_created_at, sc.id as cust_id, sc.name as cust_name,
	  ss.clone_parent_id as parent_id,
      (select ss2.name from sam_server ss2 where ss2.id = ss.clone_parent_id) as parent_name,
      (select ss3.status from sam_server ss3 where ss3.id = ss.clone_parent_id) as parent_status,
      (select ss4.created_at from sam_server ss4 where ss4.id = ss.clone_parent_id) as parent_created_at
      from sam_customer sc, sam_server ss
	  where ss.clone_parent_id is not null and ss.status in ('a','t') and ss.sam_customer_id = sc.id and sc.fake = 0
	  order by " + orders_clause)
  end

  def export_corrected_clones_to_csv
    logger.info "EXPORTING CSV"
    @corrected_clones_results = get_corrected_clones("cust_name")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Clone Server Name", "Clone Server ID", "Clone Status", "Clone Registration Date", "SAM Customer Name", "SC ID", "Parent Server Name", "Parent Server ID", "Parent Status", "Parent Registration Date"]
      @corrected_clones_results.each do |server|
        # data row
        csv_row << [server.clone_name, server.clone_id, server.status, server.clone_created_at, server.cust_name, server.cust_id, server.parent_name, server.parent_id, server.parent_status, server.parent_created_at]
      end
    end
    file_name = "corrected_clones.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  # Report - Alerts

  def alerts_report
    params[:sort] ||= "description"
    @sort_order = params[:sort]
    case (@sort_order)
    when "description" then orders_clause = "a.description"
    when "description_desc" then orders_clause = "a.description desc"
    when "msg_type" then orders_clause = "a.msg_type"
    when "msg_type_desc" then orders_clause = "a.msg_type desc"
    when "alert_count" then orders_clause = "alert_count"
    when "alert_count_desc" then orders_clause = "alert_count desc"
    else orders_clause = "a.description"
    end
    if (current_user.isScholasticType)
      conditions_clause = ["a.user_type = 's'"]
    else
      conditions_clause = [""]
    end
    @alert_counts = AlertInstance.find(:all, :select => "a.id, a.code, a.description, a.msg_type, count(*) as alert_count", :joins => "ai inner join alert a on ai.alert_id = a.id",
    :conditions => conditions_clause, :order => orders_clause, :group => "a.code")
    render(:layout => "cs_blank_layout")
  end

  def alert_type_report
    params[:sort] ||= "created_at_desc"
    @sort_order = params[:sort]
    @alert = Alert.find(params[:notification_type_id]) if !params[:notification_type_id].nil?
    @alert_type_report = get_alert_type_report(@alert, @sort_order)
    @num_rows_reported = @alert_type_report.length
    @max_rows_reportable = MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_ALERTS
    render(:layout => "cs_blank_layout", :template => "utilities/alert_list")
  end

  def get_alert_type_report(alert, sortby)
    #puts "params: #{params.to_yaml}"
    case (sortby)
    when "id" then orders_clause = "id"
    when "id_desc" then orders_clause = "id desc"
    when "cust_id" then orders_clause = "cust_id"
    when "cust_id_desc" then orders_clause = "cust_id desc"
    when "cust_name" then orders_clause = "cust_name"
    when "cust_name_desc" then orders_clause = "cust_name desc"
    when "agent_id" then orders_clause = "agent_id"
    when "agent_id_desc" then orders_clause = "agent_id desc"
    when "server_id" then orders_clause = "server_id"
    when "server_id_desc" then orders_clause = "server_id desc"
    when "server_name" then orders_clause = "server_name"
    when "server_name_desc" then orders_clause = "server_name desc"
    when "message" then orders_clause = "message"
    when "message_desc" then orders_clause = "message desc"
    when "created_at" then orders_clause = "created_at"
    when "created_at_desc" then orders_clause = "created_at desc"
    else orders_clause = "created_at"
    end

    @alert_instances = SamServer.find_by_sql("select ai.id as id, sc.id as cust_id, sc.name as cust_name, ai.agent_id as agent_id, ai.server_id as server_id, ss.name as server_name, ai.message as message, ai.created_at as created_at
	  from alert_instance ai left join sam_server ss on ai.server_id = ss.id left join sam_customer sc on ai.sam_customer_id = sc.id
	  where ai.alert_id = " + (alert.id).to_s + " order by " + orders_clause + " limit #{MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_ALERTS}")
  end

  def export_alert_type_report_to_csv
    logger.info "EXPORTING CSV"
    @alert = Alert.find(params[:notification_type_id]) if !params[:notification_type_id].nil?
    @alert_type_report_results = get_alert_type_report(@alert, "created_at_desc")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Notification ID", "Customer ID", "Customer Name", "Agent ID", "Server ID", "Server Name", "Created At", "Message"]
      @alert_type_report_results.each do |alert|
        # data row
        csv_row << [alert.id, alert.cust_id, alert.cust_name, alert.agent_id, alert.server_id, alert.server_name, alert.created_at, alert.message]
      end
    end
    file_name = @alert.description + " notifications.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  ### Reports - CSI
  #
  # Two CSI reports which have same display fields with slightly different query.
  # Report-id is used define report differences:
  #   * csi-1: new, end and merge report
  #   * csi-2: change report
  #
  def csi_messages
    params[:sort] ||= "received_date"
    @sort_order = params[:sort]
    @report_id = params[:report_id]
    @report_title = (@report_id == "csi-1") ? "CSI Messages for Organizations - New, End and Merge Report" : "CSI Messages for Organizations - Change Report"
    @csi_messages = get_csi_messages(@sort_order, @report_id)
    @num_rows_reported = @csi_messages.length
    @max_rows_reportable = MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_DEFAULT
    render(:layout => "cs_blank_layout")
  end

  def get_csi_messages(sortby, report_id)
    where_clause = (report_id == "csi-1") ? "em.message_class = \"CustomerRelationshipMessage\"" : "em.message_class = \"CustomerStatusMessage\" and em.message_text like \"%CLOSED%\""
    case (sortby)
    when "org_name" then orders_clause = "org.name"
    when "org_name_desc" then orders_clause = "org.name desc"
    when "c_ucn" then orders_clause = "c.ucn"
    when "c_ucn_desc" then orders_clause = "c.ucn desc"
    when "em_transaction_type" then orders_clause = "em.transaction_type"
    when "em_transaction_type_desc" then orders_clause = "em.transaction_type desc"
    when "em_received" then orders_clause = "em.received"
    when "em_received_desc" then orders_clause = "em.received desc"
    when "em_id" then orders_clause = "em.id"
    when "em_id_desc" then orders_clause = "em.id desc"
    when "sc_name" then orders_clause = "sc.name"
    when "sc_name_desc" then orders_clause = "sc.name desc"
    when "sc_id" then orders_clause = "sc.id"
    when "sc_id_desc" then orders_clause = "sc.id desc"
    else orders_clause = "em.id"
    end
    EsbMessage.find_by_sql("select org.name as org_name, c.ucn as c_ucn, em.transaction_type as em_transaction_type,
                            em.received as em_received, em.id as em_id, sc.name as sc_name, sc.id as sc_id
      from org
      inner join customer c on org.customer_id = c.id
      left join sam_customer sc on sc.root_org_id = org.id
      inner join esb_message em on c.ucn = em.corpid_value
      where " + where_clause +
    " order by " + orders_clause + " limit #{MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_DEFAULT}")
  end

  def export_csi_messages_to_csv
    logger.info "EXPORTING CSV"
    @report_id = params[:report_id]
    @csi_messages = get_csi_messages("received_date", @report_id)
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Org Name", "UCN", "Transaction Type", "Message Received", "ESB Message ID", "SAM Customer Name", "SAM Customer ID"]
      @csi_messages.each do |msg|
        # data row
        csv_row << [msg.org_name, msg.c_ucn, msg.em_transaction_type, msg.em_received, msg.em_id, msg.sc_name, msg.sc_id]
      end
    end
    file_name = "csi_messages.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  ### Report - Child SAM Connect Orgs - List Children Orgs that are SAM Customers and have an immediate parent Org
  #  * This query interrogates one level of child/parent relationship at a time. Hence, this means
  #    that the same organization can be listed in one row as a child, and another row as a parent.
  #    Scenario:
  #       * Org A has parent Org B
  #       * Org B has parent Org C
  #       * Org C does not have a parent
  #       * Org A and Org B are both SAM Customers
  #       * Does not matter if Org C is a SAM Customer (makes no difference to results)
  #       * In this case the report will list:
  #           > One Row    : Org A as child with Org B as parent
  #           > Another Row: Orb B as child with Org C as parent
  #

  def child_sc_orgs
    params[:sort] ||= "child_name"
    @sort_order = params[:sort]
    @child_sc_orgs = get_child_sc_orgs(@sort_order)
    @num_rows_reported = @child_sc_orgs.length
    render(:layout => "cs_blank_layout")
  end

  def get_child_sc_orgs(sortby)
    case (sortby)
    when "child_ucn" then orders_clause = "c_child.ucn"
    when "child_ucn_desc" then orders_clause = "c_child.ucn desc"
    when "child_name" then orders_clause = "child_name"
    when "child_name_desc" then orders_clause = "child_name desc"
    when "child_account_type" then orders_clause = "child_account_type"
    when "child_account_type_desc" then orders_clause = "child_account_type desc"
    when "number_of_entitlements_at_child" then orders_clause = "number_of_entitlements_at_child"
    when "number_of_entitlements_at_child_desc" then orders_clause = "number_of_entitlements_at_child desc"
    when "number_of_servers_at_child" then orders_clause = "number_of_servers_at_child"
    when "number_of_servers_at_child_desc" then orders_clause = "number_of_servers_at_child desc"
    when "parent_ucn" then orders_clause = "parent_ucn"
    when "parent_ucn_desc" then orders_clause = "parent_ucn desc"
    when "parent_name" then orders_clause = "parent_name"
    when "parent_name_desc" then orders_clause = "parent_name desc"
    when "parent_account_type" then orders_clause = "parent_account_type"
    when "parent_account_type_desc" then orders_clause = "parent_account_type desc"
    when "parent_sam_customer_id" then orders_clause = "sc_parent.id"
    when "parent_sam_customer_id_desc" then orders_clause = "sc_parent.id desc"
    when "child_is_parent" then orders_clause = "child_is_parent"
    when "child_is_parent_desc" then orders_clause = "child_is_parent desc"
    else orders_clause = "child_name"
    end
    Customer.find_by_sql("
      select
        distinct c_child.ucn as child_ucn,
        trim(o_child.name) as child_name,
        ct_child.description as child_account_type,
        count(distinct e.id) as number_of_entitlements_at_child,
        count(ss.id) as number_of_servers_at_child,
        c_parent.ucn as parent_ucn,
        trim(o_parent.name) as parent_name,
        ct_parent.description as parent_account_type,
        sc_parent.id as parent_sam_customer_id,
        if (c_child.ucn = c_parent.ucn, 'Y', 'N') as child_is_parent
      from
        customer c_child
        inner join customer_relationship cr on cr.customer_id = c_child.id
        inner join customer c_parent on cr.related_customer_id = c_parent.id
        inner join org o_child on o_child.customer_id = c_child.id
        inner join sam_customer sc_child on sc_child.root_org_id = o_child.id
        inner join org o_parent on o_parent.customer_id = c_parent.id
        left join sam_customer sc_parent on sc_parent.root_org_id = o_parent.id
        left join entitlement e on e.sam_customer_id = sc_child.id
        inner join customer_type ct_child on c_child.customer_type_id = ct_child.id
        inner join customer_type ct_parent on c_parent.customer_type_id = ct_parent.id
        inner join sam_server ss on (ss.sam_customer_id = sc_child.id and ss.status = 'a')
      where
        sc_child.active = true and
        sc_child.registration_date is not null and
        (sc_parent.id is null or sc_parent.active = true)
      group by
        sc_child.id
      order by " + orders_clause)
  end

  def cloned_servers_review
    payload = { "limit" => "100000"}
    exact_license_check = "noLicenseCheck"
    @report_type = "noLicenseCheck"
    if (params[:exact_license_check] && !params[:exact_license_check].strip.empty?)
      exact_license_check = "licenseExactCheck"
      @report_type = "licenseExactCheck"
    end
    @clones = find_review_clones(payload, exact_license_check)
    @num_rows_reported = @clones.length
    render(:layout => "cs_blank_layout")
  end

  def find_review_clones

  end

  def find_review_clones(payload, exact_license_check)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
    payload,
    CustServServicesHandler::ROUTES['clones_review_report_web_services'] + exact_license_check )
    parsed_json = ActiveSupport::JSON.decode(response.body)
    @clones = []

    if (!parsed_json["clones"].nil?)
      parsed_json["clones"].each do |c|
        x = {}
        ss = SamServer.new
        parsed_json_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(c))
        parsed_json_row.each {|k,v|
          ss[k.to_sym] = v
        }
        @clones << ss
      end
    end
    @clones_to_review = @clones
  end

  def export_clone_review_to_csv
    payload = { "limit" => "100000"}
    exact_license_check = "noLicenseCheck"
    @report_type = "noLicenseCheck"
    file_name = "clone_review_report_noLicenseCheck.csv"
    if (params[:extra_param] && params[:extra_param] == "licenseExactCheck")
      exact_license_check = "licenseExactCheck"
      file_name = "clone_review_report_exactLicenseCheck.csv"
    end
    @clones = find_review_clones(payload, exact_license_check)
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Customer Name", "Customer UCN", "Clone Parent Name", "Clone Parent ID", "Clone Parent Last Checkin","Clone Name", "Clone ID"]
      @clones.each do |c|
        # data row
        csv_row << [c.customer_name, c.ucn, c.clone_parent_name, c.clone_parent_id, c.parent_last_checkin, c.clone_name, c.clone_id]
      end
    end
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end

  def export_child_sc_orgs_to_csv
    logger.info "EXPORTING CSV"
    @child_sc_orgs = get_child_sc_orgs("child_name")
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Child UCN", "Child Name", "Child Account Type", "Number of Entitlements Assigned to Child", "Number of Servers Registered to Child","Parent UCN", "Parent Name", "Parent Account Type", "Parent SAM Customer ID", "Child is Own Parent"]
      @child_sc_orgs.each do |o|
        # data row
        csv_row << [o.child_ucn, o.child_name, o.child_account_type, o.number_of_entitlements_at_child, o.number_of_servers_at_child, o.parent_ucn, o.parent_name, o.parent_account_type, o.parent_sam_customer_id, o.child_is_parent]
      end
    end
    file_name = "child_sc_orgs.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end
  ###
  ### End of "Utilities -> Reports" methods
  ###

  def new_fake_order
    @core_processor_queue_depth = SamCentralMessageCoreProcessor.count
    @msg_queue_depth = SamCentralMessageMessaging.count
    @product_list = Product.find(:all, :order => "description")
    @grace_period_id_list = [["-none-", -1]].concat(GracePeriod.find(:all, :order => "description").collect {|p| [p.description, p.id]})
    @progress_bar_support = true
    @scrolling_support = true
    @prototype_required = true
  end

  def go_to_parent
    @parent_customer = Customer.find_parent_by_customer_id(params[:id])
    @descendant_orgs = Customer.find_descendants_minimum_field_set(@customer.ucn)
  end

  def experimentation
    render(:layout => "jquery_ui")
  end

  def show_org_details
    @org = Customer.find_details_by_ucn(params[:id])
    if (@org)
      @sam_customer = @org.sam_customer_id ? SamCustomer.find(@org.sam_customer_id) : nil
      @number_billed_to = Entitlement.count(:conditions => ["bill_to_org_id = ?", @org.id])
      @number_shipped_to = Entitlement.count(:conditions => ["ship_to_org_id = ?", @org.id])
      @number_installed_to = Entitlement.count(:conditions => ["install_to_org_id = ?", @org.id])
      render(:partial => "org_widget_org_details", :object => @org,
      :locals => {:sam_customer => @sam_customer,
        :number_billed_to => @number_billed_to,
        :number_shipped_to => @number_shipped_to,
        :number_installed_to => @number_installed_to})
    else
      render(:text => "ERROR")
    end
  end

  def show_children
    @org = Org.find(params[:id])
    render(:text => "#{@org.id}")
  end

  def get_children
    @customer = Customer.find_by_ucn(params[:id])
    @parent_customer = Customer.find_parent_by_customer_id(@customer.id)
    @descendant_orgs = Customer.find_descendants_minimum_field_set(params[:id])
    render(:partial => "org_widget_children", :object => @customer, :locals => {:descendant_orgs => @descendant_orgs, :parent_customer => @parent_customer})
  end

  def centralize_sam_customer
    raise if params[:id].nil?
    sam_customer_id = params[:id].to_i
    sam_customer = SamCustomer.find(sam_customer_id)
    message_sender = SC.getBean("messageSender")
    message_sender.sendSamCustomerAdminScopeMessage(sam_customer_id, 0)
    flash[:notice] = "Your request to centralize #{sam_customer.name} is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    if (sam_customer)
      flash[:notice] = "Your request to centralize #{sam_customer.name} was unsuccessful: #{e}"
    else
      flash[:notice] = "Your request was unsuccessful."
    end
    redirect_to(:action => :sam_customer_operations)
  end

  def decentralize_sam_customer
    raise if params[:id].nil?
    sam_customer_id = params[:id].to_i
    sam_customer = SamCustomer.find(sam_customer_id)
    message_sender = SC.getBean("messageSender")
    message_sender.sendSamCustomerAdminScopeMessage(sam_customer_id, 1)
    flash[:notice] = "Your request to decentralize #{sam_customer.name} is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    if (sam_customer)
      flash[:notice] = "Your request to decentralize #{sam_customer.name} was unsuccessful: #{e}"
    else
      flash[:notice] = "Your request was unsuccessful."
    end
    redirect_to(:action => :sam_customer_operations)
  end

  def refresh_entitlements
    message_sender = SC.getBean("messageSender")
    message_sender.sendRefreshEntitlementsMessage()
    flash[:notice] = "Your request to refresh entitlements is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    flash[:notice] = "Your request to refresh entitlements was unsuccessful: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def broadcast_license_counts
    raise if params[:id].nil?
    sam_customer_id = params[:id].to_i
    sam_customer = SamCustomer.find(sam_customer_id)
    message_sender = SC.getBean("messageSender")
    message_sender.sendBroadcastLicenseCountsMessage(sam_customer_id)
    flash[:notice] = "Your request to broadcast license counts for #{sam_customer.name} is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    if (sam_customer)
      flash[:notice] = "Your request to broadcast license counts for #{sam_customer.name} was unsuccessful: #{e}"
    else
      flash[:notice] = "Your request was unsuccessful."
    end
    redirect_to(:action => :sam_customer_operations)
  end

  def broadcast_all_license_counts
    message_sender = SC.getBean("messageSender")
    sam_customers = SamCustomer.find(:all, :conditions => "fake = false and registration_date is not null")
    sam_customers.each do |sc|
      message_sender.sendBroadcastLicenseCountsMessage(sc.id)
    end
    flash[:notice] = "Your request to broadcast all license counts is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    flash[:notice] = "Your request to broadcast all license counts was unsuccessful: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def send_updated_server_information
    message_sender = SC.getBean("messageSender")
    message_sender.sendResendServerInformationMessage(params[:server_id].nil? ? nil : params[:server_id].to_i, params[:id].nil? ? nil : params[:id].to_i)
    flash[:notice] = "Your request to send updated server information is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    flash[:notice] = "Your request to send updated server information was unsuccessful: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def scrub_license_manager_data
    message_sender = SC.getBean("messageSender")
    message_sender.sendScrubLicenseManagerDataMessage(nil, current_user.id, !params[:scrub_all_entitlements].nil?)
    flash[:notice] = "Your request to scrub License Manager data is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Your request to scrub License Manager data was unsuccessful: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def resolve_lcd_tasks
    message_sender = SC.getBean("messageSender")
    message_sender.sendResolveLicenseCountDiscrepancyTasksMessage(nil, nil)
    flash[:notice] = "Your request to resolve LCD tasks is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Your request to resolve LCD tasks was unsuccessful: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def delete_condemned_entitlements
    logger.info("params for jeff: #{params.to_yaml}")
    message_sender = SC.getBean("messageSender")
    message_sender.sendDeleteCondemnedEntitlementsMessage(-1, params[:dont_recalculate_renewals].nil?)
    flash[:msg_type] = "info"
    flash[:notice] = "Deleting Condemned Entitlements.."
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Could not delete condemned entitlements.  Please report this problem to an SAMC Administrator: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def convert_everybody_to_lmv2
    sam_customer_service = SC.getBean("samCustomerService")
    retval = sam_customer_service.activateLicenseManagerConversion(current_user.id)
    if (retval.empty?)
      flash[:notice] = "Your request to convert everyone is underway"
      flash[:msg_type] = "info"
    else
      flash[:notice] = "There are still outstanding tasks that need to be closed before you can convert everybody"
    end
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Your request to convert everybody failed fool!:  #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def update_subscriptions
    payload = {
      "method_name" => 'update_license_counts_for_subscriptions'
    }
    logger.info("******Payload: " + payload.to_s)

    response = CustServServicesHandler.new.dynamic_new_entitlements(request.env['HTTP_HOST'],
    payload,
    CustServServicesHandler::ROUTES['entitlement_web_services'])
    if response
      if response.type == 'success'
        logger.debug("request to update license counts for subscription returned success.")
        logger.info("response >>>>>> #{response.to_s}")
        flash[:notice] = ("Update license counts for subscription request created.")
      else
        logger.error "ERROR: Update license counts for subscription request returned failure: #{response.body || String.new}"
      end
    else logger.error("ERROR: no response from Web API call Update license counts for subscription.")
    end

    flash[:msg_type] = "info"
    redirect_to(:action => :qa_functions)
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Your request to update subscriptions failed.  Please report this problem to an SAMC Administrator: #{e}"
    redirect_to(:action => :qa_functions)
  end

  def send_subscription_notifications
    payload = {
      "method_name" => 'send_subscription_email_notifications',
      "sam_customer" => nil
    }
    logger.info("******Payload: " + payload.to_s)

    response = CustServServicesHandler.new.dynamic_new_entitlements(request.env['HTTP_HOST'],
    payload,
    CustServServicesHandler::ROUTES['sam_central_message_service'])
    if response
      if response.type == 'success'
        logger.debug("request to send subscription email notifications returned success.")
        logger.info("response >>>>>> #{response.to_s}")
        flash[:notice] = ("Send subscription email notifications request created.")
      else
        logger.error "ERROR: Send subscription email notifications request returned failure: #{response.body || String.new}"
      end
    else logger.error("ERROR: no response from Web API call Send subscription email notifications.")
    end

    flash[:notice] = "Your request to send subscription email notifications is in progress"
    flash[:msg_type] = "info"
    redirect_to(:action => :qa_functions)
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Your request to send subscription email notifications failed.  Please report this problem to an SAMC Administrator: #{e}"
    redirect_to(:action => :qa_functions)
  end

  def repair_tasks
    alert_service = SC.getBean("alertService")
    @num_tasks_repaired = alert_service.repairTasks()
    flash[:notice] = "Repaired #{@num_tasks_repaired} tasks"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    flash[:notice] = "Could not repair tasks.  Please report this problem to an SAMC Administrator: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def redrive_plcc_tasks
    #message_sender = SC.getBean("messageSender")
    #message_sender.sendRedrivePendingLicenseCountChangesMessage(nil)

    payload = {
      "method_name" => 'redrive_plcc_tasks',
      "task" => nil
    }
    logger.info("******Payload: " + payload.to_s)

    response = CustServServicesHandler.new.dynamic_new_entitlements(request.env['HTTP_HOST'],
    payload,
    CustServServicesHandler::ROUTES['sam_central_message_service'])
    if response
      if response.type == 'success'
        logger.debug("request to redrive plcc tasks returned success.")
        logger.info("response >>>>>> #{response.to_s}")
        flash[:notice] = ("Redrive plcc tasks request created.")
      else
        logger.error "ERROR: Redrive plcc tasks request returned failure: #{response.body || String.new}"
      end
    else logger.error("ERROR: no response from Web API call Redrive plcc tasks.")
    end

    flash[:msg_type] = "info"
    flash[:notice] = "Redriving all appropriate PLCC's"
    redirect_to(:action => :qa_functions)
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    flash[:notice] = "Could not redrive tasks.  Please report this problem to an SAMC Administrator: #{e}"
    redirect_to(:action => :qa_functions)
  end

  def prep_for_license_manager
    message_sender = SC.getBean("messageSender")
    message_sender.sendPrepLicenseManagerMessage(nil, current_user.id)
    flash[:notice] = "Your request to prepare License Manager is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e}")
    flash[:notice] = "Your request to prepare License Manager was unsuccessful: #{e}"
    redirect_to(:action => :sam_customer_operations)
  end

  def move_servers
    logger.debug "Attempting to move server(s), calling shared utility method."
    move_sam_servers(params) # calling helper method in WebAPIShared, we share it with sam servers controller

    if @failure
      # we logged the error already in web_api_shared
      flash[:notice] = "Your request to move SAM Servers was unsuccessful. #{@error_descriptions}"
      redirect_to(:action => :sam_customer_operations)
    else
      flash[:notice] = "Your request to move SAM Servers is in progress"
      flash[:msg_type] = "info"
      render(:template => "utilities/success_confirmation")
    end
  end

  def deactivate_servers
    logger.debug "Attempting to deactivate server(s), calling shared utility method."
    deactivate_sam_servers(params) # calling helper method in WebAPIShared, we share it with sam servers controller

    if @failure
      # we logged the error already in web_api_shared
      flash[:notice] = "Your request to deactivate SAM Servers was unsuccessful. #{@error_descriptions}"
      redirect_to(:action => :sam_customer_operations)
    else
      flash[:notice] = "Your request to deactivate SAM Servers is in progress"
      flash[:msg_type] = "info"
      render(:template => "utilities/success_confirmation")
    end
  end

  def move_entitlements
    entitlement_ids = params[:entitlement_ids].split(',').collect{|s| s.strip}.collect{|t| t.to_i}
    puts "entitlement_ids: #{entitlement_ids.to_yaml}"
    my_package = ResourceTransferPackage.new
    first_entitlement = Entitlement.find(entitlement_ids[0])
    my_package.setOldSamCustomerId(first_entitlement.sam_customer.id)
    my_package.setNewSamCustomerId(params[:e_new_sam_customer_id].to_i)
    resourceSet = HashSet.new
    entitlement_ids.each do |s|
      resourceSet.add(Integer.new(s))
    end
    my_package.setResourceIds(resourceSet)
    puts "The package is: #{my_package.toString()}"
    entitlement_mover = SC.getBean("entitlementMover")
    process_handle = entitlement_mover.run(my_package, Integer.new(current_user.id))
    status_codes = process_handle.getValidationFailures()
    status_codes.each do |sc|
      logger.info("PROCESS HANDLE: #{sc}")
    end
    flash[:notice] = "Your request to move entitlements is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    flash[:notice] = "Your request to move entitlements was unsuccessful"
    redirect_to(:action => :sam_customer_operations)
  end

  def create_fake_order
    @failure = false
    @error_descriptions = []
    @process_token = nil
    @process = nil
    @process_threads = nil
    @failure_reason = nil
    product_id = Integer.new(params[:product_id].to_i)
    assign_to_customer = Customer.find_by_ucn(params[:assign_to_ucn])
    raise Exception.new("ASSIGN-TO UCN does not exist") if assign_to_customer.nil?
    assign_to_org_id = assign_to_customer.org.id
    install_to_customer = Customer.find_by_ucn(params[:install_to_ucn])
    raise Exception.new("INSTALL-TO UCN does not exist") if install_to_customer.nil?
    install_to_org_id = install_to_customer.org.id
    bill_to_org_id = -1
    ship_to_org_id = -1
    if (!params[:bill_to_ucn].strip.empty?)
      bill_to_customer = Customer.find_by_ucn(params[:bill_to_ucn])
      raise Exception.new("BILL-TO UCN does not exist") if bill_to_customer.nil?
      bill_to_org_id = bill_to_customer.org.id
    end
    if (!params[:ship_to_ucn].strip.empty?)
      ship_to_customer = Customer.find_by_ucn(params[:ship_to_ucn])
      raise Exception.new("SHIP-TO UCN does not exist") if ship_to_customer.nil?
      ship_to_org_id = ship_to_customer.org.id
    end
    my_package = OrderLinePackage.new(product_id, assign_to_org_id, install_to_org_id)
    my_package.setLicenseCount(params[:license_count].to_i)
    my_package.setAssignToOrgId(Integer.new(assign_to_org_id))
    my_package.setInstallToOrgId(Integer.new(install_to_org_id))
    my_package.setBillToOrgId(Integer.new(bill_to_org_id))
    my_package.setShipToOrgId(Integer.new(ship_to_org_id))
    my_package.setSendOneEntitlement(Boolean.new(params[:send_one_entitlement] == "1"))
    my_package.setLicenseManagerConversion(Boolean.new(params[:lm_conversion] == "1"))
    if (!params[:start_date].strip.empty?)
      raise Exception.new("No subscription end date provided") if params[:end_date].strip.empty?
      start_date_year = params[:start_date].slice(0,4).to_i
      start_date_month = params[:start_date].slice(5,2).to_i - 1
      start_date_date = params[:start_date].slice(8,2).to_i
      raise Exception.new("Invalid subscription start date") if (start_date_year <= 0 || start_date_month < 0 || start_date_date <= 0)
      end_date_year = params[:end_date].slice(0,4).to_i
      end_date_month = params[:end_date].slice(5,2).to_i - 1
      end_date_date = params[:end_date].slice(8,2).to_i
      raise Exception.new("Invalid subscription end date") if (end_date_year <= 0 || end_date_month < 0 || end_date_date <= 0)
      #start_date_calendar = GregorianCalendar.new(Integer.new(start_date_year), Integer.new(start_date_month), Integer.new(start_date_date))
      my_package.setSubscriptionPeriod(start_date_year, start_date_month, start_date_date, end_date_year, end_date_month, end_date_date)
    end
    if (params[:grace_period_id] != "-1")
      raise Exception.new("No grace period start or end date provided") if params[:grace_period_start_date].strip.empty? || params[:grace_period_end_date].strip.empty?
      grace_period_id = params[:grace_period_id].to_i
      start_date_year = params[:grace_period_start_date].slice(0,4).to_i
      start_date_month = params[:grace_period_start_date].slice(5,2).to_i - 1
      start_date_date = params[:grace_period_start_date].slice(8,2).to_i
      raise Exception.new("Invalid grace period start date") if (start_date_year <= 0 || start_date_month < 0 || start_date_date <= 0)
      end_date_year = params[:grace_period_end_date].slice(0,4).to_i
      end_date_month = params[:grace_period_end_date].slice(5,2).to_i - 1
      end_date_date = params[:grace_period_end_date].slice(8,2).to_i
      raise Exception.new("Invalid grace period end date") if (end_date_year <= 0 || end_date_month < 0 || end_date_date <= 0)
      my_package.setGracePeriod(start_date_year, start_date_month, start_date_date, end_date_year, end_date_month, end_date_date, grace_period_id)
    end
    resourceSet = HashSet.new
    resourceSet.add(product_id)
    my_package.setResourceIds(resourceSet)
    puts "The package is: #{my_package.toString()}"
    fake_order_generator = SC.getBean("fakeOrderGenerator")
    process_handle = fake_order_generator.run(my_package, Integer.new(current_user.id))
    status_codes = process_handle.getValidationFailures()
    status_codes.each do |status_code|
      logger.info("status code: #{status_code}")
      @error_descriptions << status_code.getDescription()
    end
    @failure = true if @error_descriptions.length > 0
    if (!@failure)
      @process_token = process_handle.getProcessToken()
      if(!@process_token.nil?)
        logger.info("the process token is: #{@process_token}")
        @process = SamcProcess.find_by_process_token(@process_token)
        if(!@process.nil?)
          logger.info("the process id is: #{@process.id}")
          @process_threads = ProcessMessageResponse.find_incomplete_by_group(@process.id)
          if(!@process_threads.nil?)
            logger.info("the process threads are: #{@process_threads.to_yaml}")
          else
            logger.info("Unable to find process thread for process ID: " + @process.id)
          end
        else
          logger.info("Unable to find process associated with process token: " + @process_token)
        end
      else
        logger.info("Unable to find process token")
      end
    end
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    @failure = true
    @failure_reason = e.to_s
  end

  def convert_licenses
    entitlement_service = SC.getBean("entitlementService")
    entitlement_service.convertLicenses(params[:conversion_license_pool_id].to_i, params[:number_of_licenses].to_i, 2, 1)
    flash[:notice] = "Your request to move entitlements is in progress"
    flash[:msg_type] = "info"
    render(:template => "utilities/success_confirmation")
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    @failure = true
    @failure_reason = e.to_s
  end

  def request_test_emails
    @prototype_required = true
    # populate @available_test_emails with all email_type.code where email_type.available_in_test_email_utility is true
    # in order to send a test email, we need to have a method built for it to know what data to populate.
    # if .available_in_test_email_utility==true but there's no method, that email type should fail gracefully
    # and we'll know we have to switch available_in_test_email_utility to false until we build the method

    @valid_test_emails_types = EmailType.find(:all,
    :conditions => "available_in_test_email_utility AND code IS NOT null AND description IS NOT null",
    :order => "description ASC")
    @available_test_email_options = (@valid_test_emails_types.map { |item| item.description }).unshift("All") # get text descriptions and add the option for All
  end

  #######################################
  def send_test_emails
    @failure = false
    @failure_reason = nil
    @unsuccessful_emails = ""

    logger.info("Attempting to generate test emails of type(s): " + params[:email_type].to_s)
    logger.info("Recipient address: " + params[:recipient_address])

    # general design is to call one method per email type, which contains custom code to populate the specific data that email template requires
    # data will be pulled from most recent records of appropriate database tables
    # to minimize null fields and empty result sets, the various fields will not match combinations that go together unless necessary to have the email make sense
    #  example: The first name and last name for an addressee of the Updates Available email will not be the actual sam server user for the sam server for which...
    #           ...the update is available, as this would require null checking and re-querying in cases where joins return empty sets or fields are null.
    if(params[:email_type].downcase == "all")
      valid_test_emails_types = EmailType.find(:all,
      :conditions => "available_in_test_email_utility AND code IS NOT null AND description IS NOT null",
      :order => "description ASC")

      valid_test_emails_types.each do |valid_test_emails_type| #for each email type that's flagged to be processed in the database
        @email_type_code = valid_test_emails_type.code.to_s
        begin
          logger.debug("Beginning creation of test email type: " + @email_type_code)
          send("send_test_email_" + @email_type_code, params[:recipient_address]) #dynamic method call
        rescue Exception => e
          logger.error("ERROR: error caught while sending test email of type " + @email_type_code + ": " + e.to_s)
          logger.error(e.backtrace.to_s)
          @failure_reason = e.to_s
          @unsuccessful_emails += (@email_type_code + ",") #keep a comma-separated list of which types failed, just for display later
          next #continue trying other email types
        end
      end
    else
      #this isn't very clean, but we have to query again look the email_type.code up based on the description since the drop-down box is just strings
      @email_type_code = EmailType.find(:first, :conditions => ["description = ?", params[:email_type]]).code.to_s

      begin
        logger.debug("Beginning creation of test email type: " + @email_type_code)
        send("send_test_email_" + @email_type_code, params[:recipient_address])
      rescue Exception => e
        logger.error("ERROR: error caught while sending test email of type " + @email_type_code + ": " + e.to_s)
        logger.error(e.backtrace.to_s)
        @failure = true #since we couldn't complete the single email type that was requested, mark the whole job as failed
        @failure_reason = e.to_s #note that we're overwriting, so this will be just the most recent failure reason if there's more than one, but that's OK for now
        @unsuccessful_emails = @email_type_code #to be thorough, in case we change the view later
      end
    end
  end

  def create_fake_org
    logger.debug("Session_Unless")
    unless (session[:available_state_province_options])

      valid_state_province_types = StateProvince.find(:all, :select => "distinct code",
      :conditions => "code IS NOT null ",
      :order => "code ASC")
      available_state_province_options = (valid_state_province_types.map { |item| item.code }).unshift("NY")
      session[:available_state_province_options] = available_state_province_options
    end

  end

  def fake_org
    ucn = Customer.find_by_ucn(params[:ucn])      
    if (ucn)
      flash[:notice] = "Duplicate UCN"
    elsif (params[:parent_ucn] == params[:ucn])
      flash[:notice] = "Parent and Child UCNs may not match"
    else

      temp_customer=Customer.new
      temp_customer.ucn = params[:ucn]
      if (params[:select_type] == "School")
        temp_customer.customer_group_id = 12
        temp_customer.customer_type_id = 52
      elsif (params[:select_type] == "District")
        temp_customer.customer_group_id = 2
        temp_customer.customer_type_id = 75
      end
      temp_customer.customer_status_id = 1
      temp_customer.customer_added_date = Time.now

      temp_customer_address=CustomerAddress.new
      temp_customer_address.customer=temp_customer
      temp_customer_address.address_type_id = 5
      temp_customer_address.usps_record_type_id = 2
      temp_customer_address.address_line_1 = params[:address_line_1]
      temp_customer_address.city_name = params[:city]
      temp_customer_address.state_province_id = StateProvince.find_by_code(params[:state_province]).id
      temp_customer_address.postal_code = params[:zip_code]
      temp_customer_address.zip_code = params[:zip_code]
      temp_customer_address.county_code = 003
      temp_customer_address.country_id = 1
      temp_customer_address.effective_date = Time.now
      temp_customer_address.save

      temp_telephone=Telephone.new
      temp_telephone.customer=temp_customer
      temp_telephone.telephone_type_id = 5
      temp_telephone.telephone_number = params[:phone_number]
      temp_telephone.effective_date = Time.now
      temp_telephone.save

      temp_org=Org.new
      temp_org.customer = temp_customer
      temp_org.name = params[:name]
      temp_org.number_of_children = 0
      temp_org.save

      temp_customer_relationship = CustomerRelationship.new
      temp_customer_relationship.customer = temp_customer

      parent_ucn = params[:parent_ucn].strip

      if (parent_ucn.length > 0)
        parent_ucn_value = Org.find_by_ucn(parent_ucn)
        if (parent_ucn_value)
          parent_ucn_value.number_of_children+=1
          parent_ucn_value.save
          temp_customer_relationship.related_customer = Customer.find_by_ucn(params[:parent_ucn])
          temp_customer_relationship.relationship_type_id = 3
          temp_customer_relationship.effective = Time.now
          temp_customer_relationship.created_at =  Time.now
          temp_customer_relationship.updated_at = Time.now
          temp_customer_relationship.save
        else
          flash[:notice] = "Parent UCN does not exist"
        end
      end
      flash[:notice] = "Success! UCN "+params[:ucn]+" has been created"
    end
    redirect_to(:action => :create_fake_org)
  end
  
  # Gets all email type records and renders partial to produce table
  def manage_emails
    @email_type_list = EmailType.find(:all)
    render(:layout => "default_with_utilities_subtabs", :partial => 'manage_emails_view')
  end  
  
  # Handles enabling/disabling email types
  def enable_disable_emails
    email_type = EmailType.find(params[:id])
    if(email_type.status == 0)
      email_type.status = 1
    else
      email_type.status = 0
    end
    email_type.save!
    flash[:notice] = "Email type statuses updated."
    redirect_to :back
  end

  private

  def config_sam_customer_pi_chart
    @number_of_customers = SamCustomer.count(:conditions => "fake = false")
    @number_of_registered_customers = SamCustomer.count(:conditions => "fake = false and registration_date is not null")
    @pct_registered = ((@number_of_registered_customers.to_f / @number_of_customers.to_f) * 100.0).round
    @pct_non_registered = 100 - @pct_registered
  end

  def send_test_email_14(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 newUpdates[].sapling.marketingName
    #                 newUpdates[].server.name

    @sapling = Sapling.find(:first, :select => "s.*",
    :joins => "s INNER JOIN sapling_targeting st ON s.id = st.sapling_id",
    :conditions => "s.marketing_name IS NOT null AND st.sam_server_id is NOT null")
    
    params = HashMap.new
    params.put("user", get_simple_user)
    sapling = HashMap.new
    sapling.put("marketingName", @sapling.marketing_name)
    update = HashMap.new
    update.put("sapling", sapling)
    update.put("server", get_simple_server)
    newUpdates = ArrayList.new
    newUpdates << update
    params.put("newUpdates", newUpdates)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_12(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 updates[].sapling.marketingName
    #                 updates[].server.name
    #                 updates[].scheduledAt

    @sapling = Sapling.find(:first, :select => "s.*",
    :joins => "s INNER JOIN sapling_targeting st ON s.id = st.sapling_id",
    :conditions => "s.marketing_name IS NOT null AND st.sam_server_id is NOT null")
    
    params = HashMap.new
    params.put("user", get_simple_user)
    sapling = HashMap.new
    sapling.put("marketingName", @sapling.marketing_name)
    update = HashMap.new
    update.put("sapling", sapling)
    update.put("server", get_simple_server)
    update.put("scheduledAt", Time.new) #use current time
    updates = ArrayList.new
    updates << update
    params.put("updates", updates)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_13(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 successUpdates[].sapling.marketingName
    #                 successUpdates[].server.name
    #                 successUpdates[].completedAt

    @sapling = Sapling.find(:all, :select => "s.*",
    :joins => "s INNER JOIN sapling_targeting st ON s.id = st.sapling_id",
    :conditions => "s.marketing_name IS NOT null AND st.sam_server_id is NOT null",
    :limit => 2)

    params = HashMap.new
    params.put("user", get_simple_user)
    sapling0 = HashMap.new
    sapling0.put("marketingName", @sapling[0].marketing_name) #template has separate text for successful and failed update, so making one of each
    sapling1 = HashMap.new
    sapling1.put("marketingName", @sapling[1].marketing_name)
    update0 = HashMap.new
    update0.put("sapling", sapling0)
    server = get_simple_server
    update0.put("server", server)
    update0.put("completedAt", Time.new) #use current time
    update1 = HashMap.new
    update1.put("sapling", sapling1)
    update1.put("server", server)
    update1.put("completedAt", Time.new)
    successUpdates = ArrayList.new
    successUpdates << update0
    failedUpdates = ArrayList.new
    failedUpdates << update1
    params.put("successUpdates", successUpdates)
    params.put("failedUpdates", failedUpdates)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_11(recipient_address)
    #template fields: user.firstName
    #                 request.reportType
    #                 request.server.name

    @sam_server = SamServer.find(:first, :select => "ss.*, srr.report_type, srr.created_at",
    :joins => "ss INNER JOIN server_report_request srr ON ss.id = srr.sam_server_id",
    :conditions => "ss.name IS NOT null AND srr.report_type IS NOT null",
    :order => "srr.created_at desc")
    #note that @server_report_request table doesnt have its own model

    params = HashMap.new
    params.put("user", get_simple_user)
    request = HashMap.new
    server = HashMap.new
    server.put("name", @sam_server.name)
    request.put("server", server)
    request.put("reportType", @sam_server.report_type)
    params.put("request", request)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_10(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 orderNum
    #                 entitlementList[].product.samServerProduct
    #                 entitlementList[].product.desc
    #                 entitlementList[].licenseCount
    #                 entitlementList[].getShippedToOrg().name
    #                 entitlementList[].getBilledToOrg().name

    params = HashMap.new
    params.put("user", get_simple_user)
    entitlement = get_simple_entitlement
    params.put("orderNum", entitlement.get("orderNum")) #pulling order_num out into hash, but other info will come from real Java entitlement object, see queue_test_entitlement_email

    queue_test_entitlement_email(recipient_address, params, entitlement.get("id"), true)
  end

  def send_test_email_02(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 entitlement.product.desc
    #                 entitlement.getShippedToOrg().name
    #                 entitlement.getBilledToOrg().name
    #                 licensesAutomaticallyAllocated
    #                 entitlement.samCustomer.id
    #                 entitlement.orderNum

    #note: select product that's a sam_server_product to ensure template displays the license count field
    params = HashMap.new
    params.put("user", get_simple_user)
    params.put("licensesAutomaticallyAllocated", true)

    queue_test_entitlement_email(recipient_address, params, get_simple_entitlement.get("id"), false)
  end

  def send_test_email_05(recipient_address)
    #template fields: user.firstName
    #                 user.samCustomer.name
    #                 serverAddress.firstName
    #                 serverAddress.lastName
    #                 serverAddress.emailAddress
    #                 serverAddress.phoneNumber
    #                 serverAddress.jobTitle.description

    sam_server_address = SamServerAddress.find(:first, :select => "ssa.*, jt.description",
    :joins => "ssa INNER JOIN job_title jt ON ssa.job_title_id = jt.id",
    :conditions => "ssa.first_name IS NOT null AND ssa.last_name IS NOT null AND ssa.email_address IS NOT null AND ssa.phone_number IS NOT null",
    :order => "created_at desc")

    params = HashMap.new
    user = get_simple_user
    user.put("samCustomer", get_simple_sam_customer)
    params.put("user", user)
    serverAddress = HashMap.new
    serverAddress.put("firstName", sam_server_address.first_name)
    serverAddress.put("lastName", sam_server_address.last_name)
    serverAddress.put("emailAddress", sam_server_address.email_address)
    serverAddress.put("phoneNumber", sam_server_address.phone_number)
    jobTitle = HashMap.new
    jobTitle.put("description", sam_server_address.description)
    serverAddress.put("jobTitle", jobTitle)
    params.put("serverAddress", serverAddress)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_04(recipient_address)
    #template fields: notificationType
    #                 incitingSsu.FirstName
    #                 incitingSsu.LastName
    #                 incitingSsu.Username
    #                 inciting
    #                 ssu.FirstName
    #                 ssu.LastName
    #                 ssu.Username

    params = HashMap.new
    params.put("notificationType", "enabled")
    incitingSsu = HashMap.new
    sam_server_user = get_simple_sam_server_user #note that capitalization is messed up in this template, have to do extra steps
    incitingSsu.put("FirstName", sam_server_user.get("firstName"))
    incitingSsu.put("LastName", sam_server_user.get("lastName"))
    incitingSsu.put("Username", sam_server_user.get("username"))
    params.put("incitingSsu", incitingSsu)
    params.put("inciting", true)
    #TODO: currently only doing case where current sam_server_user is the inciting one, maybe send a seperate email to hit the template's other case
    params.put("ssu", incitingSsu) #just copying. This parameter not used unless notificationType=="enabled" and inciting==false

    queue_test_email(recipient_address, params)
  end

  def send_test_email_03(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 user.token

    params = HashMap.new
    params.put("user", get_simple_user)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_01(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 user.addedByUser.firstName
    #                 user.addedByUser.lastName
    #                 user.token

    params = HashMap.new
    user = get_simple_user
    user.put("addedByUser", get_simple_sam_server_user) #getting sam_server_user instead of user for addedByUser just so names will be different
    params.put("user", user)
    queue_test_email(recipient_address, params)
  end

  def send_test_email_US1(recipient_address)
    #template fields: schools[].name
    #                 schools[].address1
    #                 schools[].address2
    #                 schools[].address3
    #                 schools[].city
    #                 schools[].state
    #                 schools[].postalCode
    #                 schools[].Server.Name
    #                 user.firstName
    #                 user.lastName

    @sam_server_school_info = SamServerSchoolInfo.find(:first, :select => "*",
    :conditions => "address1 IS NOT null AND city IS NOT null AND state IS NOT null",
    :order => "created_at desc")

    params = HashMap.new
    params.put("user", get_simple_user())
    schools = ArrayList.new
    school0 = HashMap.new
    school0.put("name", @sam_server_school_info.name)
    school0.put("address1", @sam_server_school_info.address1)
    school0.put("address2", @sam_server_school_info.address2)
    school0.put("address3", @sam_server_school_info.address3)
    school0.put("city", @sam_server_school_info.city)
    school0.put("state", @sam_server_school_info.state)
    school0.put("postalCode", @sam_server_school_info.postal_code)
    server = get_simple_server
    server.put("Name", server.get("name")) #extra step because capitalization is messed up in template
    school0.put("Server", server)
    schools << school0
    params.put("schools", schools)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_RS(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 name
    #                 address1
    #                 address2
    #                 address3
    #                 city
    #                 state
    #                 postalCode

    @sam_server_school_info = SamServerSchoolInfo.find(:first, :select => "*",
    :conditions => "address1 IS NOT null AND city IS NOT null AND state IS NOT null",
    :order => "created_at desc")

    params = HashMap.new
    params.put("user", get_simple_user())
    params.put("name", @sam_server_school_info.name)
    params.put("address1", @sam_server_school_info.address1)
    params.put("address2", @sam_server_school_info.address2)
    params.put("address3", @sam_server_school_info.address3)
    params.put("city", @sam_server_school_info.city)
    params.put("state", @sam_server_school_info.state)
    params.put("postalCode", @sam_server_school_info.postal_code)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SRJ(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 name
    #                 address1
    #                 address2
    #                 address3
    #                 city
    #                 state
    #                 postalCode

    @sam_server_school_info = SamServerSchoolInfo.find(:first, :select => "*",
    :conditions => "address1 IS NOT null AND city IS NOT null AND state IS NOT null",
    :order => "created_at desc")

    params = HashMap.new
    params.put("user", get_simple_user())
    params.put("name", @sam_server_school_info.name)
    params.put("address1", @sam_server_school_info.address1)
    params.put("address2", @sam_server_school_info.address2)
    params.put("address3", @sam_server_school_info.address3)
    params.put("city", @sam_server_school_info.city)
    params.put("state", @sam_server_school_info.state)
    params.put("postalCode", @sam_server_school_info.postal_code)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_PC(recipient_address)
    #template fields: user.firstName
    #                 user.lastName

    params = HashMap.new
    params.put("user", get_simple_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_LMAR(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 user.samCustomer.name

    params = HashMap.new
    user = get_simple_user
    user.put("samCustomer", get_simple_sam_customer)
    params.put("user", user)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_HSNLM(recipient_address)
    #template fields: samCustomer.name
    #                 samCustomer.Org.Customer.Ucn
    #                 entitlement.Product.Desc
    #                 entitlement.LicenseCount

    @sam_customer = SamCustomer.find(:first, :select => "sc.*, c.ucn",
    :joins => "sc INNER JOIN org o ON sc.root_org_id = o.id INNER JOIN customer c ON o.customer_id = c.id",
    :order => "created_at desc")

    @entitlement = Entitlement.find(:first, :select => "e.*, p.description",
    :joins => "e INNER JOIN product p ON e.product_id = p.id",
    :conditions => "e.license_count IS NOT null AND e.license_count > 0 AND p.description IS NOT null",
    :order => "created_at desc")

    params = HashMap.new
    samCustomer = HashMap.new
    samCustomer.put("name", @sam_customer.name)
    org = HashMap.new
    customer = HashMap.new
    customer.put("Ucn", @sam_customer.ucn)
    org.put("Customer", customer)
    samCustomer.put("Org", org)
    params.put("samCustomer", samCustomer)
    entitlement = HashMap.new
    product = HashMap.new
    product.put("Desc", @entitlement.description)
    entitlement.put("Product", product)
    entitlement.put("LicenseCount", @entitlement.license_count)
    params.put("entitlement", entitlement)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_HSLM(recipient_address)
    #template fields: samCustomer.name
    #                 samCustomer.Org.Customer.Ucn
    #                 entitlement.Product.Description
    #                 entitlement.LicenseCount

    @sam_customer = SamCustomer.find(:first, :select => "sc.*, c.ucn",
    :joins => "sc INNER JOIN org o ON sc.root_org_id = o.id INNER JOIN customer c ON o.customer_id = c.id",
    :order => "created_at desc")

    @entitlement = Entitlement.find(:first, :select => "e.*, p.description",
    :joins => "e INNER JOIN product p ON e.product_id = p.id",
    :conditions => "e.license_count IS NOT null AND e.license_count > 0 AND p.description IS NOT null",
    :order => "created_at desc")

    params = HashMap.new
    samCustomer = HashMap.new
    samCustomer.put("name", @sam_customer.name)
    org = HashMap.new
    customer = HashMap.new
    customer.put("Ucn", @sam_customer.ucn)
    org.put("Customer", customer)
    samCustomer.put("Org", org)
    params.put("samCustomer", samCustomer)
    entitlement = HashMap.new
    product = HashMap.new
    product.put("Description", @entitlement.description)
    entitlement.put("Product", product)
    entitlement.put("LicenseCount", @entitlement.license_count)
    params.put("entitlement", entitlement)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_LMARSP(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 granted
    #                 samCustomer.name
    #                 reasons[]

    params = HashMap.new
    params.put("user", get_simple_user)
    params.put("granted", false) #only hitting case for granted==false right now so reasons[] will be displayed
    params.put("samCustomer", get_simple_sam_customer)
    reasons = ArrayList.new
    reasons << "It appears that there are schools missing from your registered servers"
    reasons << "It appears that there is a large discrepancy in your registered servers' license counts and the counts that Scholastic has on record"
    params.put("reasons", reasons)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_REGTOKEN(recipient_address)
    #template fields: registrationToken.firstName
    #                 registrationToken.lastName
    #                 registrationToken.token

    #TODO: maybe create a new model for sam_registration_token table.  Just latching on to a random existing model here
    @sam_registration_token = SamServer.find_by_sql("SELECT * FROM sam_registration_token WHERE first_name IS NOT null AND last_name IS NOT null AND token IS NOT null ORDER BY created_at desc LIMIT 1")

    params = HashMap.new
    registrationToken = HashMap.new
    registrationToken.put("firstName", @sam_registration_token[0].first_name)
    registrationToken.put("lastName", @sam_registration_token[0].last_name)
    registrationToken.put("token", @sam_registration_token[0].token)
    params.put("registrationToken", registrationToken)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_ITS14E(recipient_address)
    #template fields: samServerUser.firstName

    params = HashMap.new
    params.put("samServerUser", get_simple_sam_server_user)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_DASHR(recipient_address)
    #template fields: user.firstName

    params = HashMap.new
    params.put("user", get_simple_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_UMARSP(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 samCustomer.name

    params = HashMap.new
    params.put("user", get_simple_user())
    params.put("samCustomer", get_simple_sam_customer())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_HSNEWREG(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 samCustomer.name
    #                 ucn

    @sam_customer = SamCustomer.find(:first, :select => "sc.*, c.ucn",
    :joins => "sc INNER JOIN org o ON sc.root_org_id = o.id INNER JOIN customer c ON o.customer_id = c.id",
    :order => "created_at desc")

    params = HashMap.new
    params.put("user", get_simple_user())
    samCustomer = HashMap.new
    samCustomer.put("name", @sam_customer.name)
    params.put("samCustomer", get_simple_sam_customer)
    params.put("ucn", @sam_customer.ucn)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_MAWEL(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 user.token

    params = HashMap.new
    params.put("user", get_simple_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_MAGRNT(recipient_address)
    #template fields: user.firstName
    #                 user.lastName

    params = HashMap.new
    params.put("user", get_simple_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SUSTUBADDED(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName
    #                 ssu.username
    #                 ssu.password

    params = HashMap.new
    params.put("ssu", get_simple_sam_server_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SUSTUBCH(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName
    #                 ssu.username
    #                 ssu.password

    params = HashMap.new
    params.put("ssu", get_simple_sam_server_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SUADDEDSC(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName

    params = HashMap.new
    params.put("ssu", get_simple_sam_server_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SUSTUBADDEDSC(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName

    params = HashMap.new
    params.put("ssu", get_simple_sam_server_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SUSTUBCHSC(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName
    #                 ssu.username
    #                 ssu.password

    params = HashMap.new
    params.put("ssu", get_simple_sam_server_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SUADDED(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName

    params = HashMap.new
    params.put("ssu", get_simple_sam_server_user())

    queue_test_email(recipient_address, params)
  end

  def send_test_email_OC(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 org.name

    #org table doesnt have its own created_at
    @org = Org.find(:first, :select => "o.*",
    :joins => "o INNER JOIN sam_customer sc ON o.id = sc.root_org_id",
    :order => "sc.created_at desc")

    params = HashMap.new
    params.put("user", get_simple_user())
    org = HashMap.new
    org.put("name", @org.name)
    params.put("org", org)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_OM(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 terminatingOrg.name
    #                 survivingOrg.name

    #org table doesnt have its own created_at
    @orgs = Org.find(:all, :select => "o.*",
    :joins => "o INNER JOIN sam_customer sc ON o.id = sc.root_org_id",
    :order => "sc.created_at desc",
    :limit => 2)

    params = HashMap.new
    params.put("user", get_simple_user())
    terminatingOrg = HashMap.new
    terminatingOrg.put("name", @orgs[0].name)
    survivingOrg = HashMap.new
    survivingOrg.put("name", @orgs[1].name)
    params.put("terminatingOrg", terminatingOrg)
    params.put("survivingOrg", survivingOrg)

    queue_test_email(recipient_address, params)
  end

  def send_test_email_SR(recipient_address)
    #template fields: org.Customer.getMailingOrLocationAddress()
    #                 user.firstName
    #                 user.lastName
    #                 name
    #                 address1
    #                 address2
    #                 address3
    #                 city
    #                 state
    #                 postalCode
    #                 org.name

    @sam_server_school_info = SamServerSchoolInfo.find(:first, :select => "*",
    :conditions => "address1 IS NOT null AND city IS NOT null AND state IS NOT null AND postal_code IS NOT null",
    :order => "created_at desc")

    #org table doesnt have its own created_at
    @org = Org.find(:first, :select => "o.*",
    :joins => "o INNER JOIN sam_customer sc ON o.id = sc.root_org_id",
    :order => "sc.created_at desc")

    params = HashMap.new
    params.put("user", get_simple_user())
    params.put("name", @sam_server_school_info.name)
    params.put("address1", @sam_server_school_info.address1)
    params.put("address2", @sam_server_school_info.address2)
    params.put("address3", @sam_server_school_info.address3)
    params.put("city", @sam_server_school_info.city)
    params.put("state", @sam_server_school_info.state)
    params.put("postalCode", @sam_server_school_info.postal_code)

    queue_test_org_email(recipient_address, params, @org.id)
  end

  def send_test_email_REM(recipient_address)
    #template fields: environment
    #                 esbMessages[].getCorpIdValue()
    #                 esbMessages[].getMessageClass()
    #                 esbMessages[].getTransactionType()
    #                 esbMessages[].getMessageInfoType()
    #                 esbMessages[].getExceptionClass()

    @esb_message = EsbMessage.find(:first, :select => "*",
    :conditions => "corpid_value IS NOT null AND message_class IS NOT null AND transaction_type IS NOT null AND msg_info_type IS NOT null AND exception_class IS NOT null",
    :order => "message_timestamp DESC")

    params = HashMap.new
    params.put("environment", "PROD:")

    if(@esb_message)
      queue_test_esb_message_email(recipient_address, params, @esb_message.id)
    else
      logger.error("Couldnt proccess test email type " + @email_type_code + ", no adequate DB records to satisfy template fields.")
      @unsuccessful_emails += (@email_type_code + ",")
      @failure_reason = "No adequate db records to satisfy template fields."
    end
  end

  def send_test_email_HSE1D(recipient_address)
    #template fields: user.firstName
    #                 outOfComplianceProducts[].getProductDescription()
    #                 outOfComplianceProducts[].outOfComplianceProducts()

    params = HashMap.new
    params.put("user", get_simple_user)

    queue_test_expired_licenses_email(recipient_address, params)
  end

  def send_test_email_HSE8D(recipient_address)
    #template fields: user.firstName
    #                 outOfComplianceProducts[].getProductDescription()
    #                 outOfComplianceProducts[].outOfComplianceProducts()

    params = HashMap.new
    params.put("user", get_simple_user)

    queue_test_expired_licenses_email(recipient_address, params)
  end

  def send_test_email_E21DTME1D(recipient_address)
    #template fields: user.firstName
    #                 outOfComplianceProducts[].getProductIdValue()
    #                 outOfComplianceProducts[].getTotalExpiredLicenses()
    #                 outOfComplianceProducts[].getProductDescription()

    params = HashMap.new
    params.put("user", get_simple_user)

    queue_test_expired_licenses_email(recipient_address, params)
  end

  def send_test_email_E21DTME8D(recipient_address)
    #template fields: user.firstName
    #                 outOfComplianceProducts[].getProductIdValue()
    #                 outOfComplianceProducts[].getTotalExpiredLicenses()
    #                 outOfComplianceProducts[].getProductDescription()

    params = HashMap.new
    params.put("user", get_simple_user)

    queue_test_expired_licenses_email(recipient_address, params)
  end

  def send_test_email_COMBINEDE1D(recipient_address)
    #template fields: user.firstName
    #                 outOfComplianceProducts[].getTotalExpiredLicenses()
                         
    params = HashMap.new
    params.put("user", get_simple_user)
                         
    queue_test_expired_licenses_email(recipient_address, params)
  end
                         
  def send_test_email_COMBINEDE8D(recipient_address)
    #template fields: user.firstName
    #                 outOfComplianceProducts[].getTotalExpiredLicenses()
                         
    params = HashMap.new
    params.put("user", get_simple_user)
                         
    queue_test_expired_licenses_email(recipient_address, params)
  end
  

  def send_test_email_SAUCN(recipient_address)
    #template fields: teacher.firstName
    #                 teacher.lastName
    #                 student.username

    params = HashMap.new
    params.put("teacher", get_simple_sam_server_user)
    params.put("student", get_simple_sam_server_user) #actually pulling the same record again, but for only username this time

    queue_test_expired_licenses_email(recipient_address, params)
  end

  def send_test_email_NEWNGCONV(recipient_address)
    #template fields: user.firstName
    #                 user.lastName
    #                 entitlementList[].getOrderNum()
    #                 entitlementList[].product.desc
    #                 entitlementList[].licenseCount
    #                 entitlementList[].getShippedToOrg()
    #                 entitlementList[].getBilledToOrg()

    params = HashMap.new
    params.put("user", get_simple_user)

    queue_test_entitlement_email(recipient_address, params, get_simple_entitlement.get("id"), true)
  end
  
  
  def send_test_email_ILMAR(recipient_address)
    #template fields: fullName
    #                 title
    #                 telephoneNum

    params = HashMap.new
    user = get_simple_user
    
    params.put("fullName", "#{user.get('firstName')} #{user.get('lastName')}")
    params.put("title", user.get("title"))
    params.put("telephoneNum", user.get("phone"))

    queue_test_email(recipient_address, params)
  end
  
  
  def send_test_email_MSADMINTOKEN(recipient_address)
    #template fields: name
    #                 tokenValue

    params = HashMap.new
    user = get_simple_user
    
    params.put("name", "#{user.get('firstName')} #{user.get('lastName')}")
    params.put("tokenValue", user.get("token"))

    queue_test_email(recipient_address, params)
  end
  
  def send_test_email_MRIEXP(recipient_address)
    #template fields: daysTillExpiration

    params = HashMap.new
    
    params.put("daysTillExpiration", "5")

    queue_test_email(recipient_address, params)
  end
  
  
  def send_test_email_NXPTSR(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName
    #                 ssu.username
    #                 ssu.password

    params = HashMap.new
    ssu = get_simple_sam_server_user
    
    params.put("ssu", ssu)

    queue_test_email(recipient_address, params)
  end
  
  def send_test_email_SUASEXP(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName
    #                 daysTillExpiration

    params = HashMap.new
    ssu = get_simple_sam_server_user
    
    params.put("ssu", ssu)
    params.put("daysTillExpiration", "5")

    queue_test_email(recipient_address, params)
  end
  
  
  def send_test_email_SUCEXP(recipient_address)
    #template fields: ssu.firstName
    #                 ssu.lastName
    #                 daysTillExpiration

    params = HashMap.new
    ssu = get_simple_sam_server_user
    product = get_simple_product
    
    params.put("ssu", ssu)
    params.put("daysTillExpiration", "5")
    params.put("product", product)

    queue_test_email(recipient_address, params)
  end
  
  
  #TODO: there are many different template variations under the DASHN email type, which breaks the
  #functionality of this email template tester. Need to revisit this type later.
  #def send_test_email_DASHN(recipient_address)
  #template fields: classes[].name
  #                 student.firstName
  #                 student.lastName

  #   params = HashMap.new
  #   classes = ArrayList.new
  #   classes << get_simple_sam_server_class_info
  #   params.put("classes", classes)
  #   params.put("student", get_simple_sam_server_user)
  #
  #  queue_test_dashboard_notification_email(recipient_address, params)
  #end

  #~~~~~~~~~~~~~~~ begin shared email test helper methods  ~~~~~~~~~~~~~~~
  def get_simple_sam_customer
    sam_customer = SamCustomer.find(:first, 
    :order => "created_at desc")

    samCustomer = HashMap.new
    samCustomer.put("id", sam_customer.id)
    samCustomer.put("name", sam_customer.name)
    return samCustomer
  end

  def get_simple_server
    sam_server = SamServer.find(:first, 
    :conditions => ["status = ? AND server_type != ?", 'a', SamServer.TYPE_UNREGISTERED_GENERIC ],
    :order => "id DESC")
    
    server = HashMap.new
    server.put("id", sam_server.id)
    server.put("name", sam_server.name)
    return server
  end

  def get_simple_user
    user = User.find(:first, :select => "u.*, jt.description",
    :joins => "u INNER JOIN sam_customer sc ON u.sam_customer_id=sc.id INNER JOIN job_title jt ON u.job_title_id = jt.id",
    :conditions => "u.token IS NOT null AND u.added_by_user_id IS NOT null",
    :order => "u.created_at desc")

    u = HashMap.new
    u.put("id", user.id) #always get id because in some cases, we'll get the real java object in later
    u.put("firstName", user.first_name)
    u.put("lastName", user.last_name)
    u.put("token", user.token)
    u.put("title", user.description)
    u.put("phone", user.phone)
    
    return u
  end

  def get_simple_entitlement
    entitlement = Entitlement.find(:first, :select => "e.*, p.sam_server_product, p.description",
    :joins => "e INNER JOIN product p ON e.product_id = p.id",
    :conditions => "e.license_count IS NOT null AND e.license_count > 0 AND p.sam_server_product AND p.description IS NOT null AND e.bill_to_org_id IS NOT null AND e.ship_to_org_id IS NOT null",
    :order => "e.created_at desc")

    e = HashMap.new
    e.put("id", entitlement.id) #always get id because in some cases, we'll get the real java object in later
    e.put("orderNum", entitlement.order_num)
    return e
  end

  def get_simple_sam_server_user
    sam_server_user = SamServerUser.find(:first, 
    :order => "created_at desc")

    ssu = HashMap.new
    ssu.put("id", sam_server_user.id)
    ssu.put("firstName", sam_server_user.first_name)
    ssu.put("lastName", sam_server_user.last_name)
    ssu.put("username", sam_server_user.username)
    ssu.put("password", sam_server_user.password)
    return ssu
  end

  def get_simple_sam_server_class_info
    sam_server_class_info = SamServerClassInfo.find(:first, 
    :order => "created_at desc")

    ssci = HashMap.new
    ssci.put("id", sam_server_class_info.id)
    ssci.put("name", sam_server_class_info.name)
    return ssci
  end
  
  def get_simple_product
    product = Product.find(:first)

    p = HashMap.new
    p.put("desc", product.description)
    return p
  end

  def queue_test_email(recipient_address, params)
    logger.debug("Completed creation of test " + @email_type_code + " email, queueing")
    reference_service = SC.getBean("referenceService")
    email_service = SC.getBean("emailService")
    #signature: public void queueTest(String recipientAddress, EmailMessageType type, Map<String, Object> params)
    email_service.queueTest(recipient_address, reference_service.retrieveEmailMessageTypeByCode(@email_type_code), params)
  end

  def queue_test_entitlement_email(recipient_address, params, entitlement_id, templateRequiresList)
    logger.debug("Completed creation of test " + @email_type_code + " email, queueing")
    reference_service = SC.getBean("referenceService")
    email_service = SC.getBean("emailService")
    entitlementService = SC.getBean("entitlementService")
    email_service.setEntitlementService(entitlementService)
    #signature: public void queueTestEntitlementEmail(String recipientAddress, EmailMessageType type, Map<String, Object> params, int entitlementId, boolean templateRequiresList)
    email_service.queueTestEntitlementEmail(recipient_address, reference_service.retrieveEmailMessageTypeByCode(@email_type_code), params, entitlement_id, templateRequiresList)
  end

  def queue_test_org_email(recipient_address, params, org_id)
    logger.debug("Completed creation of test " + @email_type_code + " email, queueing")
    reference_service = SC.getBean("referenceService")
    email_service = SC.getBean("emailService")
    orgService = SC.getBean("orgService")
    email_service.setOrgService(orgService)
    #signature: public void queueTestOrgEmail(String recipientAddress, EmailMessageType type, Map<String, Object> params, int orgId)
    email_service.queueTestOrgEmail(recipient_address, reference_service.retrieveEmailMessageTypeByCode(@email_type_code), params, org_id)
  end

  def queue_test_esb_message_email(recipient_address, params, esb_message_id)
    logger.debug("Completed creation of test " + @email_type_code + " email, queueing")
    reference_service = SC.getBean("referenceService")
    email_service = SC.getBean("emailService")

    #signature: public void queueTestESBMessageEmail(String recipientAddress, EmailMessageType type, Map<String, Object> params, int esb_message_id)
    email_service.queueTestESBMessageEmail(recipient_address, reference_service.retrieveEmailMessageTypeByCode(@email_type_code), params, esb_message_id)
  end

  def queue_test_expired_licenses_email(recipient_address, params)
    logger.debug("Completed creation of test " + @email_type_code + " email, queueing")
    #finding product_description and total_expired_licenses here, they have to be passed outside of the params map to the Java service, constructor will be called there instead of a lookup
    @email_message = EmailMessage.find(:first, :select => "em.*, emc.value AS product_number",
    :joins => "em INNER JOIN email_message_context emc ON em.id=emc.email_message_id",
    :conditions => "emc.name LIKE 'productIdValue%' AND emc.value IS NOT null AND LENGTH(emc.value) > 1",
    :order => "em.generated_date DESC")
    product_number = (@email_message && @email_message.product_number) ? @email_message.product_number : nil

    @email_message = EmailMessage.find(:first, :select => "em.*, emc.value AS total_expired_licenses",
    :joins => "em INNER JOIN email_message_context emc ON em.id=emc.email_message_id",
    :conditions => "emc.name LIKE 'totalExpiredLicenses%' AND emc.value IS NOT null AND LENGTH(emc.value) > 1",
    :order => "em.generated_date DESC")
    total_expired_licenses = (@email_message && @email_message.total_expired_licenses) ? @email_message.total_expired_licenses.to_i : 0  #note that emc.value is a string in the DB

    if(product_number && total_expired_licenses > 0)
      reference_service = SC.getBean("referenceService")
      email_service = SC.getBean("emailService")

      #signature: public void queueTestExpiredLicensesEmail(String recipientAddress, EmailMessageType type, Map<String, Object> params, String productNumber, int totalExpiredLicenses)
      email_service.queueTestExpiredLicensesEmail(recipient_address, reference_service.retrieveEmailMessageTypeByCode(@email_type_code), params, product_number, total_expired_licenses.to_i) #total_expired_licenses is stored as string in DB, convert to int
    else
      logger.error("Couldn't proccess test email type " + @email_type_code + ", no adequate DB records to satisfy template fields.")
      @unsuccessful_emails += (@email_type_code + ",")
      @failure_reason = "No adequate db records to satisfy template fields."
    end
  end
  #~~~~~~~~~~~~~~~ end shared email test helper methods  ~~~~~~~~~~~~~~~

  def get_detailed_info_for_ucn(p_ucn)
    @org = Customer.find_details_by_ucn(p_ucn)
    @sam_customer = @org.sam_customer
    @number_billed_to = Entitlement.count(:conditions => ["bill_to_org_id = ?", @org.id])
    @number_shipped_to = Entitlement.count(:conditions => ["ship_to_org_id = ?", @org.id])
    @number_installed_to = Entitlement.count(:conditions => ["install_to_org_id = ?", @org.id])
  end

  def config_sam_server_line_chart
    start_date = Date.today - 30
    ss_reg_stats = SamServer.find(:all, :select => "date(created_at) as x_value, count(id) as y_value",
    :conditions => "created_at >= '#{start_date}' and active = true", :group => "x_value")
    @sorted_stats, @x_labels, @y_max, @highest_count = form_history_line_chart(ss_reg_stats, 30, 5)
  end

  def config_sam_customer_line_chart
    start_date = Date.today - 30
    sc_reg_stats = SamCustomer.find(:all, :select => "date(registration_date) as x_value, count(id) as y_value",
    :conditions => "registration_date >= '#{start_date}' and fake = false", :group => "x_value")
    @sc_sorted_stats, @sc_x_labels, @sc_y_max, @sc_highest_count = form_history_line_chart(sc_reg_stats, 30, 5)
  end

  def form_history_line_chart(the_list, size, x_step)
    sorted_stats = []
    highest_count = 0
    the_list.each do |srs|
      highest_count = srs.y_value.to_i if srs.y_value.to_i > highest_count
      srs.x_value[/(\d+)\-(\d+)\-(\d+)/]
      sorted_stats << Stats.new(Date.new(y=$1.to_i,m=$2.to_i,d=$3.to_i), srs.y_value)
    end
    start_date = Date.today - size
    for i in 1..size do
      (sorted_stats << Stats.new(start_date, 0)) if !(sorted_stats.collect{|ss| ss.stat_date}.include?(start_date))
      start_date = start_date + 1
    end
    sorted_stats.sort!{|a,b| a.stat_date <=> b.stat_date}
    #logger.info(sorted_stats.to_yaml)
    #logger.info("highest count is: #{highest_count}")
    final_sorted_stats = ""
    final_sorted_stats << sorted_stats[0].stat_count.to_s
    sorted_stats.slice(1, sorted_stats.length - 1).each{|ss| final_sorted_stats << ",#{ss.stat_count}"}
    x_labels = "|"
    for i in 0..x_step
      x_labels << (sorted_stats[x_step*i].stat_date).strftime("%b %d") << "|"
    end
    y_max = ((highest_count / 10) + 1) * 10
    return final_sorted_stats, x_labels, y_max, highest_count
  end

end

class Stats
  attr_accessor :stat_date, :stat_count
  def initialize(stat_date, stat_count)
    @stat_date = stat_date
    @stat_count = stat_count
  end

end
