require 'date'
begin
  import 'sami.web.SC'
  import 'java.util.HashSet'
  import 'java.lang.Integer'
  import 'sami.scholastic.api.process.resource_transfer.ResourceTransferPackage'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
#require 'geoip'
require 'fastercsv'

class HomeController < ApplicationController

  #layout 'new_layout_with_jeff_stuff'
  layout 'default'

  def index
    
    if (!logged_in?)
      logger.info("in home index; session[:return_to] = #{session[:return_to]}")
      flash[:notice] = flash[:notice] unless flash[:notice].nil?
      redirect_to(:action => :login, :controller => :account)
      return
    end
    
    #config_sam_customer_pi_chart
    config_sam_server_line_chart
    
    config_sam_customer_line_chart
	
	  #@number_of_sam_customers = SamCustomer.count
	  #@number_of_unregistered_servers = SamServer.count(:conditions => ["server_type = ?", SamServer.TYPE_UNREGISTERED_GENERIC])
    #@alert_groups = AlertInstance.group_recent_by_alert(current_user)
    #@recent_sam_servers = SamServer.get_recently_installed
  end
  
  def search_by_name
  end
  
  def save_widget_coordinates
    logger.info("params: #{params.to_yaml}")
    widget = Widget.find_by_code(params[:widget_code])
    widget_page = WidgetPage.find_by_code(params[:page_code])
    widget_layout = WidgetLayout.find(:first, :conditions => ["widget_id = ? and widget_page_id = ?", widget.id, widget_page.id])
    if (widget_layout.nil?)
      WidgetLayout.create(:user => @current_user, :widget => widget, :widget_page => widget_page, :x_offset => params[:x_offset], :y_offset => params[:y_offset])
    else
      widget_layout.x_offset = params[:x_offset]
      widget_layout.y_offset = params[:y_offset]
      widget_layout.save
    end
    render(:text => "none")
  end
  
  def search_loading
    @url = request.url
    puts "url: #{@url}"
    alert_codes = Alert.find(:all).collect {|a| a.code}
    puts "alert_codes: #{alert_codes.to_yaml}"
    render(:layout => "cs_blank_layout")
  end

  # Exports a CSV file for the registered SAM EE Customers
  def export_registered_customers_to_csv
    logger.info "EXPORTING CSV"
    sam_customers = get_registered_sam_customers
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["SAM EE Customer ID", "SAM EE Customer Name", "State", "SAMC Registration Date", "Number of Registered SAM Servers", "SAM Server Connectivity", "Number of Unmatched Schools"]
      sam_customers.each do |sam_customer|
        # data row
        csv_row << [sam_customer.sam_customer_id, sam_customer.sam_customer_name, sam_customer.state_code, sam_customer.registration_date.strftime(DATE_FORM), sam_customer.sam_server_count, sam_customer.connectivity, sam_customer.unmatched_school_count]
      end
    end
    file_name = "registered_customers.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end  
  
  #################
  # AJAX ROUTINES #
  #################
    
  def update_progress
    puts "we're in"
    render(:text => "#{(params[:the_count].to_i)*2}")
  end
  
  def update_sam_customers_table
    #puts "params: #{params.to_yaml}"
    #sam_customers = SamCustomer.paginate(:page => params[:page], :order => sam_customers_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
     registered_sam_customers = SamCustomer.paginate(:page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE,
                                      :select => "trim(sc.name) as sam_customer_name, sc.id as sam_customer_id, sc.registration_date, count(distinct a.id) as problematic_agent_count,
                                                  (100 - round((count(a.id) / count(ss.id) * 100))) as connectivity, sp.code as state_code, count(sssi.id) as unmatched_school_count,
                                                  count(distinct ss.id) as sam_server_count",
                                      :joins => "sc inner join org on sc.root_org_id = org.id 
                                                  inner join customer c on org.customer_id = c.id
                                                  inner join customer_address ca on ca.customer_id = c.id
                                                  inner join state_province sp on ca.state_province_id = sp.id
                                                  inner join address_type atype on ca.address_type_id = atype.id
                                                  inner join sam_server ss on ss.sam_customer_id = sc.id  
                                                  left join sam_server_school_info sssi on (sssi.sam_server_id = ss.id and sssi.org_id is null)                                                
                                                  left join agent a on (a.sam_server_id = ss.id and (time_to_sec(timediff(now(),a.next_poll_at)) > 86400))",
                                      :conditions => ["sc.registration_date is not null and atype.code = ? and sc.fake = false and ss.status = 'a'", AddressType.MAILING_CODE],
                                      :group => "sc.id", :order => sam_customers_sort_by_param(params[:sort]))
    render(:partial => "sam_customers_table", 
           :locals => {:sam_customer_collection => registered_sam_customers,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element]}, :layout => false)
  end
  
  def license_manager_data
    out_of_compliance_counts = SamCustomer.out_of_compliance_counts(license_manager_data_sort_by_param(params[:sort])).paginate(:page => params[:page], :per_page => 5)
    #out_of_compliance_counts = out_of_compliance_instances.paginate(:page => params[:page], :per_page => 2)
    logger.info("out_of_compliance_counts: #{out_of_compliance_counts.total_entries}")
    render(:partial => "license_manager_data", :locals => {:out_of_compliance_counts => out_of_compliance_counts})
  end
  
  def update_out_of_compliance_table
    out_of_compliance_counts = SamCustomer.out_of_compliance_counts(license_manager_data_sort_by_param(params[:sort])).paginate(:page => params[:page], :per_page => 5)
    #out_of_compliance_counts = out_of_compliance_instances.paginate(:page => params[:page], :per_page => 2)
    logger.info("out_of_compliance_counts: #{out_of_compliance_counts.total_entries}")
    render(:partial => "out_of_compliance_info", :locals => {:out_of_compliance_counts => out_of_compliance_counts,
                                                     :current_user => @current_user,
                                                     :status_indicator => "license_manager_loading",
                                                     :update_element => "out_of_compliance_table"})
  end
  
  def samc_users_data
    @users = User.find_currently_logged_in
    render(:partial => "logged_in_users", :locals => {:users => @users});
  end
  
  def schools_on_sam_servers_data
    @num_schools_requiring_manual_match = SamServerSchoolInfo.count(:joins => "sssi inner join sam_server ss on sssi.sam_server_id = ss.id inner join sam_customer sc on ss.sam_customer_id = sc.id", 
                                                  :conditions => "sc.fake = false and ss.status = 'a' and (sssi.status = '#{SamServerSchoolInfo.STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE}' or
                                                  sssi.status = '#{SamServerSchoolInfo.STATUS_NOT_RESOLVED}')")
    ## TODO: Jeff - Should we add statuses t and p to this?                                                  
    @num_schools_requiring_cm_match = SamServerSchoolInfo.count(:joins => "sssi inner join sam_server ss on sssi.sam_server_id = ss.id inner join sam_customer sc on ss.sam_customer_id = sc.id", 
                                                  :conditions => "sc.fake = false and ss.status = 'a' and sssi.status = '#{SamServerSchoolInfo.STATUS_PUBLISHED}'")
    render(:partial => "schools_on_sam_servers_data", :locals => {:num_schools_requiring_manual_match => @num_schools_requiring_manual_match, 
                                                              :num_schools_requiring_cm_match => @num_schools_requiring_cm_match})
  end
  
  def get_registered_sam_customers
    registered_sam_customers = SamCustomer.find(:all,
                                                :select => "trim(sc.name) as sam_customer_name, sc.id as sam_customer_id, sc.registration_date, count(distinct a.id) as problematic_agent_count, count(distinct ss.id) as sam_server_count, 
                                                            (100 - round((count(a.id) / count(ss.id) * 100))) as connectivity, sp.code as state_code, count(sssi.id) as unmatched_school_count",
                                                :joins => "sc inner join org on sc.root_org_id = org.id 
                                                           inner join customer c on org.customer_id = c.id
                                                           inner join customer_address ca on ca.customer_id = c.id
                                                           inner join state_province sp on ca.state_province_id = sp.id
                                                           inner join address_type atype on ca.address_type_id = atype.id
                                                           inner join sam_server ss on ss.sam_customer_id = sc.id
                                                           left join sam_server_school_info sssi on (sssi.sam_server_id = ss.id and sssi.org_id is null) 
                                                           left join agent a on (a.sam_server_id = ss.id and (time_to_sec(timediff(now(),a.next_poll_at)) > 86400))",
                                                :conditions => ["sc.registration_date is not null and atype.code = ? and sc.fake = false and ss.status = 'a'", AddressType.MAILING_CODE],
                                                :group => "sc.id", :order => "registration_date desc") 
    return registered_sam_customers
  end  
  
  private
  
  def license_manager_data_sort_by_param(sort_by_arg)
    case sort_by_arg
      
      when "sam_customer_name" then "sam_customer_name"
      when "product_name" then "product_name"
      when "out_of_compliance_count" then "out_of_compliance_count"
    
      when "product_name_reverse" then "product_name desc"
      when "out_of_compliance_count_reverse" then "out_of_compliance_count desc"
      when "sam_customer_name_reverse" then "sam_customer_name desc"
      
      else "sam_customer_name"
    end
  end
  
  def sam_customers_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "sam_customer_name" then "sc.name"
      when "sam_customer_state" then "sp.code"
      when "registration_date" then "sc.registration_date desc"
      when "number_registered_servers" then "sam_server_count desc"
      when "sc_index" then "si.description, org.name"
      when "connectivity" then "connectivity"
      when "unmatched_school_count" then "unmatched_school_count desc"
            
      when "sam_customer_name_reverse" then "sc.name desc"
      when "sam_customer_state_reverse" then "sp.code desc"
      when "registration_date_reverse" then "sc.registration_date"
      when "number_registered_servers_reverse" then "sam_server_count"
      when "connectivity_reverse" then "connectivity desc"
      when "unmatched_school_count_reverse" then "unmatched_school_count"

      else "sp.code"
    end
  end
  
  def get_twinzmq_queue_depths
    @alt_depth = SamCentralMessageAlt.count
    @auth_depth = SamCentralMessageAuth.count
    @commander_depth = SamCentralMessageCommander.count
    @core_audit_depth = SamCentralMessageCoreAudit.count
    @core_email_depth = SamCentralMessageCoreEmail.count
    @core_processor_depth = SamCentralMessageCoreProcessor.count
    @messaging_depth = SamCentralMessageMessaging.count
  end
  
  def get_school_status_counts
    @num_schools_requiring_manual_match = SamServerSchoolInfo.count(:joins => "sssi inner join sam_server ss on sssi.sam_server_id = ss.id inner join sam_customer sc on ss.sam_customer_id = sc.id", 
                                                  :conditions => "sc.fake = false and ss.status = 'a' and (sssi.status = '#{SamServerSchoolInfo.STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE}' or
                                                  sssi.status = '#{SamServerSchoolInfo.STATUS_NOT_RESOLVED}')")
    ## TODO: Jeff - Should we add statuses t and p to this?                                                  
    @num_schools_requiring_cm_match = SamServerSchoolInfo.count(:joins => "sssi inner join sam_server ss on sssi.sam_server_id = ss.id inner join sam_customer sc on ss.sam_customer_id = sc.id", 
                                                  :conditions => "sc.fake = false and ss.status = 'a' and sssi.status = '#{SamServerSchoolInfo.STATUS_PUBLISHED}'") 
  end

  def config_sam_customer_pi_chart
    @number_of_customers = SamCustomer.count(:conditions => "fake = false") 
    @number_of_registered_customers = SamCustomer.count(:conditions => "fake = false and registration_date is not null")
    @pct_registered = ((@number_of_registered_customers.to_f / @number_of_customers.to_f) * 100.0).round
    @pct_non_registered = 100 - @pct_registered
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