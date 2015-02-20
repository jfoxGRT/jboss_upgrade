    require 'fastercsv'

class AuthUsersController < SamCustomersController
  
  before_filter :load_auth_user, :set_breadcrumb
  
  #layout 'new_layout_with_jeff_stuff'
  layout 'default'
  
  def index
    @auth_user_count = AuthUser.count(:conditions => "sam_customer_id = #{@sam_customer.id}")
    @prototype_required = true
    @widget_list << Widget.new("auth_status", "Auth Status", nil, 450, 500)
    @widget_list << Widget.new("profile_status", "Auth Profile Status", nil, 300, 600)
  end
  
  
  def show
    @auth_user = AuthUser.find(params[:id])
    @sam_server_users = SamServerUser.find(:all, :select => "*, type as s_type", :conditions => ["auth_user_id = ?", @auth_user.id])
    @schools = SamServerUser.find(:all, :select => "distinct sssi.id, sssi.name, ss.id as sam_server_id, ss.name as sam_server_name, 
                    sssi.status as school_status, sssi.org_id as school_org_id, c.ucn",
                    :joins => "ssu inner join sam_server ss on ssu.sam_server_id = ss.id 
                    inner join sam_server_school_info sssi on sssi.sam_server_id = ss.id 
                    inner join sam_server_school_info_user_mapping sssium on (sssium.user_id = ssu.user_id and sssium.sam_school_id = sssi.sam_school_id) 
                    inner join auth_user au on ssu.auth_user_id = au.id
                    left join org on sssi.org_id = org.id
                    left join customer c on org.customer_id = c.id",
                    :conditions => ["au.id = ?", @auth_user.id])
  end
  
  
  #update_sam_customer_auth_users method calls the get_sam_customer_servers method and renders a layout
  #separating so that CSV functionality can call get_customer_auth_users method directly without rendering a layout
  def update_sam_customer_auth_users
    @auth_users = get_customer_auth_users(params[:sort].nil? ? "username" : params[:sort])

    render(:partial => "sam_customer_auth_users_table", 
           :locals => {:auth_user_collection => @auth_users,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :sam_customer_id => params[:sam_customer_id]}, :layout => false)
  end
  
  
  def get_customer_auth_users(sortby="username")
    AuthUser.find(:all, :select => "au.*", 
                        :joins => "au", 
                        :conditions => ["au.sam_customer_id = ?", @sam_customer.id], 
                        :order => sam_customer_auth_users_sort_by_param(sortby))
  end
  
    
  def export_auth_users_customer_page_to_csv
    logger.debug "Exporting Auth Users CSV from Customer page"
    @auth_users_search_result = get_customer_auth_users("auth_user_id")
    
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Auth User ID", "Username", "Type", "Created", "Last Updated", "Profile Merge", "Name", "Email", "Sam Servers"]
      @auth_users_search_result.each do |auth_user|
        # data row
    	sam_server_users = auth_user.sam_server_users
    	servers = ""
      email_string = ""
      name_string = ""
    	
      sam_server_users.each do |sam_server_user|
        if sam_server_user.first_name && sam_server_user.last_name
          name_string += sam_server_user.first_name + " " + sam_server_user.last_name
          name_string += "; " unless sam_server_user == sam_server_users.last
        end
        
        if sam_server_user.email
          email_string += sam_server_user.email
          email_string += "; " unless sam_server_user == sam_server_users.last
        end
        
        servers += sam_server_user.sam_server.name
        servers += "; " unless sam_server_user == sam_server_users.last 
      end
	    
	    csv_row << [auth_user.id, auth_user.username, auth_user.type, auth_user.created_at.strftime('%I:%M:%S %p %m/%d/%y'), auth_user.updated_at.strftime('%I:%M:%S %p %m/%d/%y'), (auth_user.enabled ? 'true' : 'false'), name_string, email_string, servers]
      
      end
    end
    file_name = "auth_users_search.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end
  
  
  def search
  	#put whole array from sam customers search form into session
    #when a request for csv export comes in, :sam_customer will not be included in the request
    if (params[:auth_user])
      session[:auth_user] = params[:auth_user]
    end
  	payload = params[:auth_user]
  	@auth_users = find_auth_users(payload, FINDER_LIMIT) 
    
    @num_rows_reported = @auth_users.length

    if(request.xhr?) #if an ajax request...
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end
  end
  
  
  def export_auth_users_search_to_csv
    logger.info "Exporting Auth Users Search to CSV"
    auth_user_search_results = get_auth_users # server-side CSV always uses default sort, not necessarily current sort in finder display 
    
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Auth User ID", "Username", "Type", "UUID", "Created", "Last Updated", "Profile Merge", "SAM Customer ID", "Active Token ID", "SAM Servers"]
      auth_user_search_results.each do |auth_user|
        #populating each data row with database fields
        csv_row << [auth_user.id, auth_user.username, auth_user.type, auth_user.uuid, auth_user.created_at.strftime(DATE_FORM), auth_user.updated_at.strftime(DATE_FORM), auth_user.enabled, auth_user.sam_customer_id, auth_user.active_token_id, auth_user.get_sam_servers_string ]
      end
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => AUTH_USER_FINDER_RESULTS_FILENAME)
  end
  
  def status_for
    auth_user_id = params[:auth_user_id]
    logger.info "Auth Status Auth user id: #{auth_user_id}"
    render(:partial => "auth_status", :locals => {:auth_user_id => auth_user_id})
  end
  
  def profile_status_for
    auth_user_id = params[:auth_user_id]
    logger.info "Profile Status Auth user id: #{auth_user_id}"
    http_host = request.env["HTTP_HOST"]
    logger.info "Request object host: #{http_host}"
    if(RAILS_ENV == "development")
      check_profile_url = "http://#{http_host}/auth/api/check-profile/#{auth_user_id}"
    else
      check_profile_url = "https://#{http_host}/auth/api/check-profile/#{auth_user_id}"
    end
    logger.info "Check profile URL: #{check_profile_url}"
    parsed_url = URI.parse("#{check_profile_url}")
    logger.info "Parsed URL: #{parsed_url}"
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    if(RAILS_ENV == "development")
      logger.info "Not using SSL"
    else
      # Only use SSL for production environment
      http.use_ssl = true
    end
    request = Net::HTTP::Get.new(parsed_url.request_uri)
    response = http.request(request).body
    logger.info "response: #{response}" 
    parsed_json = ActiveSupport::JSON.decode(response)
    if(!parsed_json["status"].nil?)
      status = parsed_json["status"]
      logger.info "status: #{status}"
    end
    if(!parsed_json["reason"].nil?)
      reason = parsed_json["reason"]
      logger.info "reason: #{reason}"
    end
    if(!parsed_json["fields"].nil?)
      fields = parsed_json["fields"]
      logger.info "fields: #{fields}"
    end
    render(:partial => "profile_status", :locals => {:auth_user_id => auth_user_id, :status => status, :reason => reason, :fields => fields})
  end
  
  protected
  
  def load_auth_user
    @auth_user = AuthUser.find(params[:auth_user_id]) if !params[:auth_user_id].nil?
  end
  
  
  private
  
  def set_breadcrumb
    @site_area_code = AUTH_USERS_CODE
  end
  
  def find_auth_users(payload, limit)
      payload['delim'] = 'htmlBreak'
      response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
              payload,
              CustServServicesHandler::ROUTES['authuser_finder_web_services'] + "#{limit.to_s}")
      parsed_json = ActiveSupport::JSON.decode(response.body)
	  @auth_users = []
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
		  parsed_json["auth_users"].each do |e|
		  au = AuthUser.new
				  e.each {|k,v|
			  au[k.to_sym] = v
		  }
		  
		  @auth_users << au
		  end
	  end	  
			
	@ret_customers = @auth_users
  end
  
  
  # query for a sorted result set of SAM Servers via ActiveRecord.
  # this method is somewhat deprecated; only used for large result sets where Finder's WebAPI limit is problematic.
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
end
