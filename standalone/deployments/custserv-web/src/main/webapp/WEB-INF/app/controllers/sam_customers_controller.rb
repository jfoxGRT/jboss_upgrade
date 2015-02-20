require 'java'
import 'java.util.HashMap'
import 'java.util.Properties'
import 'java.lang.Character'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
require 'sam_customer_manager/defaultDriver'
require 'fastercsv'

class SamCustomersController < StateProvincesController
  
  include SamCustomerManager
  
  before_filter :load_sam_customer, :except => [:update_table, :search, :export_sam_customers_to_csv]
  
  layout 'default'
  
  SITEID_INSUFFICIENT_PERMISSIONS_MSG = "Permissions required to edit"
  SITEID_ACTIVE_SERVER_MSG = "Customer has active hosted server"
  SITEID_IN_USE_MSG = "That Hosted Site ID is aready in use."
  INVALID_SITEID_LENGTH_MSG = "Invalid input for Hosted Site ID. Must be a letter followed by 9 digits, ex. h000000312, OR the word - integration - followed by any number of alphanumeric characters"
  INVALID_CLEVER_ID_MSG = "The Clever ID should consist only of alphabets and numbers"
  CLEVER_ID_NEEDS_SITE_ID = "Hosted Site ID required to enter Clever ID."
  CLEVER_TOKEN_NEEDS_CLEVER_ID = "A Clever ID is required to save a Clever Token."
  CLEVER_ID_NEEDS_CLEVER_TOKEN = "A Clever Token is required to save a Clever ID."
  
  def states
     config_sam_customer_pi_chart
     @sam_customer = SamCustomer.new
     country_id = Country.find_by_code("US").id
     @state_provinces = StateProvince.find(:all, :conditions => ["country_id = ?", country_id])
     samcSystem = SamcSystem.find(:all).first
     @current_license_manager_version = samcSystem.current_license_manager_version
     
     @prototype_required = true # required for Ajax.Request, like changing the default LM version
  end
  
  
  def index
    puts "params: #{params.to_yaml}"
	  redirect_to(:action => :states) if (@state_province.nil? || current_user.nil?)
    clear_sam_customer_session_variables
    sam_customers = SamCustomer.find(:all, :select => "sc.*, c.ucn as sc_ucn, si.description as sc_index, fsc.user_id as favorite",
                                          :joins => "sc inner join org on sc.root_org_id = org.id 
                                                     inner join customer c on org.customer_id = c.id 
                                                     inner join customer_address ca on ca.customer_id = c.id 
                                                     inner join scholastic_index si on sc.scholastic_index_id = si.id
                                                     left join favorite_sam_customers fsc on (fsc.sam_customer_id = sc.id and fsc.user_id = " + current_user.id.to_s + ")", 
                                          :conditions => ["ca.address_type_id = 5 and ca.state_province_id = ?", @state_province.id], :order =>  "org.name")
    #@sam_customers = SamCustomer.find(:all, :select => "sc.*, c.ucn as sc_ucn, si.description as sc_index",
    #                                      :joins => "sc inner join org on sc.root_org_id = org.id 
    #                                                 inner join customer c on org.customer_id = c.id 
    #                                                 inner join customer_address ca on ca.customer_id = c.id 
    #                                                 inner join scholastic_index si on sc.scholastic_index_id = si.id", 
    #                                      :conditions => ["ca.address_type_id = 5 and ca.state_province_id = ?", @state_province.id], :order =>  "org.name")
    @sam_customers = sam_customers.paginate(:page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    @number_of_registered_customers = sam_customers.select{|sc| !sc.registration_date.nil?}.length
    @pct_registered = ((@number_of_registered_customers.to_f / sam_customers.length.to_f) * 100.0).round
    @pct_non_registered = 100 - @pct_registered
    
    @prototype_required = true
  end
  
  
  def new
    @sam_customer = SamCustomer.new
    @mode = "Add"
    #@permissions = Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC, :order => "name")
    
    @has_manage_site_id_permission = current_user.hasPermission?(Permission.manage_siteids)
    @siteid_message = SITEID_INSUFFICIENT_PERMISSIONS_MSG
    
    render(:template => "sam_customers/form")
  end
  
  
  def create
    @sam_customer = SamCustomer.new(params[:sam_customer])
    @mode = "Add"
    @has_manage_site_id_permission = current_user.hasPermission?(Permission.manage_siteids)
    @siteid_message = SITEID_INSUFFICIENT_PERMISSIONS_MSG
    @sam_customer.name = @sam_customer.root_org.name.strip if (params[:sam_customer_use_default_name] == "1" && @sam_customer.root_org && @sam_customer.root_org.name)
    siteid = params[:sam_customer][:siteid]
    params[:sam_customer][:siteid] = siteid.to_s.strip
    
    if(params[:sam_customer][:siteid] && params[:sam_customer][:siteid].to_s.strip.length < 1)
      params[:sam_customer][:siteid] = nil #make sure we write null instead of empty string into the database in case other methods are looking specifically for null
    end
    
    if(params[:sam_customer][:siteid] && !params[:sam_customer][:siteid].empty? && (!(params[:sam_customer][:siteid].to_s.strip =~ /^integration/i) && (params[:sam_customer][:siteid].to_s.strip.downcase =~ /[a-z]{1}\d{9}/).nil?))
      flash[:notice] = INVALID_SITEID_LENGTH_MSG
      render(:template => "sam_customers/form", :siteid => params[:sam_customer][:siteid])
    else
      failure = true
      failure_reasons = Array.new
      
      logger.debug "Attempting to create new sam customer Web API call."
      payload = {
        :user_id => current_user.id.to_s,
        :method_name => 'create-sam-customer',
        :use_default_name => (params[:sam_customer_use_default_name] == "1" ? 'true' : 'false'),
        :sam_customer_attributes_json => params[:sam_customer].to_json
      }
      
      logger.info "submitting request to create sam customer with payload: #{payload.to_yaml}"
      
      response = CustServServicesHandler.new.dynamic_new_create_sam_customer(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_customer'])
      
      logger.info "response.type = #{response.type}, code = #{response.code}"
      logger.debug "response = #{response.to_s}"
      response_data = nil
      if response
        if response.type == 'success' #doesn't mean customer was created, only that request was handled successfully
          logger.info "request to Web API to create sam customer returned success, checking creation status(es)..."
          
          if response.body
            begin
              response_data = ActiveSupport::JSON.decode(response.body)
              
              if (response_data['creation_statuses'] and !response_data['creation_statuses'].empty?)
                logger.error "ERROR: request to Web API call to create sam customer failed: #{response_data['creation_statuses']}"
                failure_reasons << response_data['creation_statuses'] #not necessarily errors, could be legitimate validation failures like siteID already in use
              else
                logger.info "request to Web API call to create sam customer was successful, new sam customer created!"
                failure = false
              end
              
            rescue ActiveSupport::JSON::ParseError => parse_error
              logger.error "ERROR: invalid JSON response from Web API call to create sam customer: #{parse_error.to_s}"
            end
          else
            # this should not happen. in the absence of any creation_statuses we could call this success, but being safe here
            logger.error "ERROR: no response body from Web API call to create sam customer"
          end # end of if response.body
          
        else
          logger.info "ERROR: non-success response for request to create sam customer : #{response.type} : #{response.body}"
          failure_reasons << response.body
        end # end of if response.type == 'success'
        
      else logger.error "ERROR: no response from Web API call to create sam customer"
      end
        
      if failure
        failure_reasons.each do |failure_reason|
          flash[:notice] = failure_reason
        end
        render(:template => "sam_customers/form")
        return
      else
        logger.info "Added sam customer #{@sam_customer.id} successfully!"
        flash[:notice] = "Added #{@sam_customer.name} successfully"
        flash[:msg_type] = "info"
        redirect_to(:action => :states)
      end
    end
    
    rescue Exception => e
      logger.error("ERROR: exception caught creating new sam customer: #{e.to_s}")
      flash[:notice] = "Your request could not be processed at this time.  If this problem persists, please contact the system administrator."
      render(:template => "sam_customers/form")
  end
  
  
  def show
    @sam_customer = SamCustomer.find(params[:id])
    # Separately get list of customer admins to ensure a proper count on customer home page
    @sam_customer_admins = []
    @sam_customer.users.each do |user|
        if (user.isCustomerType && user.active)
            @sam_customer_admins << user
        end
    end
    @batch_process_excluded = @sam_customer.lm_conversion_blacklist
    @state = store_state_in_session(@sam_customer)
	  @license_manager = SamCustomerSamcComponent.find_by_sam_customer_and_component_code(@sam_customer, "LM")
    @active_server_count = SamServer.count(:conditions => ["sam_customer_id = ? and active = true", @sam_customer.id])
    if (@active_server_count > 0)
      num_servers_not_connecting = SamCustomer.find_number_of_problematic_servers(params[:id])
      @google_meter_value = 100 - (((num_servers_not_connecting.to_f / @active_server_count.to_f) * 100.0).round())
    end
	num_servers_with_atleast_one_src_quiz_preference = SamCustomer.find_number_of_servers_with_atleast_one_src_quiz_preference(params[:id])
	server_src_quiz_activation_dates = nil
    if (num_servers_with_atleast_one_src_quiz_preference.to_i > 0)
	  @src_quiz_preferences = "Activated"
      server_src_quiz_activation_dates = SrcQuizPreferences.find_server_src_quiz_activation_dates(params[:id])
    else
	  @src_quiz_preferences = "Not Activated"
	end
    @earliest_quiz_activation_date = ""
    if(server_src_quiz_activation_dates != nil)
      server_src_quiz_activation_dates.each do |date|
        if(@earliest_quiz_activation_date == "")
          @earliest_quiz_activation_date = date.quiz_activation_date
        elsif(Time.parse(date.quiz_activation_date) < Time.parse(@earliest_quiz_activation_date))
          @earliest_quiz_activation_date = date.quiz_activation_date
        end
      end
    end
    logger.info "Earliest quiz activation date: #{Time.parse(@earliest_quiz_activation_date)}"
    @matched_school_count = SamServerSchoolInfo.find_by_sql(["select count(*) as matched_school_count from sam_server_school_info sssi
                                                             inner join sam_server ss on sssi.sam_server_id = ss.id
                                                             where ss.sam_customer_id = ? and ss.status = 'a' and sssi.org_id is not null",params[:id]])[0].matched_school_count.to_i
    @unmatched_school_count = SamServerSchoolInfo.find_by_sql(["select count(*) as unmatched_school_count from sam_server_school_info sssi
                                                             inner join sam_server ss on sssi.sam_server_id = ss.id
                                                             where ss.sam_customer_id = ? and ss.status = 'a' and sssi.org_id is null",params[:id]])[0].unmatched_school_count.to_i
    if (@matched_school_count > 0 || @unmatched_school_count > 0)
      @matched_school_pct = ((@matched_school_count.to_f / (@matched_school_count + @unmatched_school_count)) * 100.0).round
      @unmatched_school_pct = 100 - @matched_school_pct
    end
    clear_sam_customer_session_variables
	tasks = Task.find_for_sam_customer(@sam_customer)
	@tasks = {}
	tasks.each do |t|
		@tasks[t.code] = t
	end
    @favorite = FavoriteSamCustomer.find(:first, :conditions => ["sam_customer_id = ? and user_id = ?", @sam_customer.id, current_user.id])
    
    @pending_hosting_rules_for_server = SamCustomer.get_pending_hosting_enrollment_rules(@sam_customer.get_hosted_server)
    @most_recent_hosting_rules_delivered = SamCustomer.get_most_recent_hosting_enrollment_rule_delivery(@sam_customer.get_hosted_server)
  end

  ###########################################################################################
  ## create a new pending hosting enrollment rule for a hosted server and invoke connect now
  ###########################################################################################
  def send_hosting_rules
    logger.info "sending hosting rules"
    @sam_customer = SamCustomer.find(params[:id])
    hosted_server = @sam_customer.get_hosted_server
    if(!hosted_server.nil?)
      logger.info "hosted server id: #{@sam_customer.get_hosted_server.id}"
      pending_hosting_rules_for_server = SamCustomer.get_pending_hosting_enrollment_rules(hosted_server)
      if(pending_hosting_rules_for_server.nil?)
        success = SamCustomer.create_pending_hosting_enrollment_rules(hosted_server)
        if(success)
          call_connect_now(hosted_server)
          flash[:notice] = ("Hosting enrollment rules will be sent at next agent checkin")
          flash[:msg_type] = "info"
        else
          flash[:notice] = ("No active entitlement for SAM Customer")
        end
      else
        logger.info "There are already pending hosting enrollment rules"
      end
    else
      flash[:notice] = ("No active hosted server at this SAM Customer")
    end
    redirect_to :action => :show, :id => params[:id]
  end
                                                              
  def call_connect_now(server)
    # Call ConnectNow
    retval = {:status => "0", :message => "S3 service is not available"}
    agent_id = (server.nil? || server.agent.nil?) ? nil : server.agent.id
    payload = { "subj" => "" , "mode" => ""}
                                                              
    if agent_id.nil?
      logger.debug(" CSsiteCLECN-3a - agent id is nil - stop")
      puts "      puts CSsiteCLECN-3a - agent id is nil - stop"
      retval = {:status => "2", :message => "There is no registered agent for this sam server"}
    else
      begin
        response = CustServServicesHandler.new.dynamic_new_request_agent_connect_now(request.env['HTTP_HOST'], payload,
                                                                                     CustServServicesHandler::ROUTES['agents_web_services'] +
                                                                                     "#{agent_id.to_s}" + "/connectNow")
        if(response.code == "200")                                                        
          parsed_json = ActiveSupport::JSON.decode(response.body)
          if(!parsed_json["success"].nil?)
            successval = parsed_json["success"]
            if successval == "true"
              logger.info(" CSsiteCLECN-3d - successfully agent connect now request")
              puts "      puts CSsiteCLECN-3d - successfully agent connect now request"
              retval = {:status => "1", :message => "Success - Agent is now connecting"}
            else
              logger.info(" CSsiteCLECN-3e - not successfully in agent connect now - successval = :#{parsed_json["exception"]}:")
              puts "      puts CSsiteCLECN-3e - not successfully in agent connect now - successval = :#{successval}:"
              retval = {:status => "3", :message => parsed_json["exception"]}
            end
          end
        else
            retval = {:status => "3", :message => "SAMC API call returned #{response.code}"}  
        end    
      rescue Timeout::Error => e
        retval = {:status => "3", :message => "Timeout occurred during API call. Check logs for specific errors."}  
      end     
    end
    ################# End of connectnow
  end
  
  def lm_opt_in
    @sam_customer = SamCustomer.find(params[:sc_id])

      payload = {
                "sam_customer_id" => params[:sc_id],
                "first_name" => params[:first_name],
                "last_name"  => params[:last_name],
                "job_title"  => params[:job_title],
                "telephone_number" => params[:telephone_number],
                "method_name" => 'create_lm_opt_in_task'
      }
      logger.info("******Payload: " + payload.to_s)
      
      response = CustServServicesHandler.new.dynamic_edit_sam_customer(request.env['HTTP_HOST'],
                                                                   payload,
                                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_customer'] + 
                                                                   "#{@sam_customer.id}/license_manager/")
      if response
        if response.type == 'success'
          logger.debug("request to create LM opt task returned success.")
          logger.info("response >>>>>> #{response.to_s}")
          flash[:notice] = ("License Management request created.")
        else
          logger.error "ERROR: License Management request returned failure: #{response.body || String.new}"  
        end  
      else logger.error("ERROR: no response from Web API call License Management request.")
      end
         
      redirect_to(:action => :show, :id => @sam_customer.id)     
  end 
  
  def lm_opt_out
    @sam_customer = SamCustomer.find(params[:sc_id])

      payload = {
                "sam_customer_id" => params[:sc_id],
                "method_name" => 'lm_opt_out'
      }
      logger.info("******Payload: " + payload.to_s)
      
      response = CustServServicesHandler.new.dynamic_edit_sam_customer(request.env['HTTP_HOST'],
                                                                   payload,
                                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_customer'] + 
                                                                   "#{@sam_customer.id}/license_manager/")
      if response
        if response.type == 'success'
          logger.debug("request to opt out of LM returned success.")
          logger.info("response >>>>>> #{response.to_s}")
          flash[:notice] = ("Customer is Opted Out of License Management.")
        else
          logger.error "ERROR: License Management request returned failure: #{response.body || String.new}"  
        end  
      else logger.error("ERROR: no response from Web API call License Management request.")
      end
         
      redirect_to(:action => :show, :id => @sam_customer.id)     
  end    
  
  def edit
    @sam_customer = SamCustomer.find(params[:id])
    @sc_hosted_server = @sam_customer.get_hosted_server
    @mode = "Edit"
    
    @has_manage_site_id_permission = current_user.hasPermission?(Permission.manage_siteids)
	@has_manage_clever_id_permission = current_user.hasPermission?(Permission.manage_cleverids)
    @customer_has_active_hosted_server = (@sam_customer.number_of_active_hosted_sam_servers > 0)
    @siteid = @sam_customer.siteid #need to store this separately for a minute because some view logic depends on what's saved in the DB, while other GUI logic relies on instance variable
	@cleverid = @sam_customer.cleverid #need to store this separately for a minute because some view logic depends on what's saved in the DB, while other GUI logic relies on instance variable
    @siteid_message = ""
    
    if(@customer_has_active_hosted_server) #note that this takes precedence over any permissions
      @siteid_message = SITEID_ACTIVE_SERVER_MSG
    elsif(!@has_manage_site_id_permission)
      @siteid_message = SITEID_INSUFFICIENT_PERMISSIONS_MSG
    end
        
    # the License Manager versions that we allow users to switch to. locking down this way requires code update when new
    # LM versions come out, but seems preferable to allowing freeform input.
    # @available_license_manager_versions is used only for straightforward allowed changes of LM version.
    #   - customer can't simply change to or from version 1 -- other process for that.
    #   - if customer has no current LM version at all, this is not the way to opt them in -- other process for that.
    @available_license_manager_versions = @sam_customer.get_available_license_manager_versions
    
    @prototype_required = true
    render(:template => "sam_customers/form")
  end
  
  
  
  def update
    @mode = "Edit"
    @sam_customer = SamCustomer.find(params[:id])
    @has_manage_site_id_permission = current_user.hasPermission?(Permission.manage_siteids) #these variables shouldn't be needed here... 
    @customer_has_active_hosted_server = (@sam_customer.number_of_active_hosted_sam_servers > 0) #... will only be used if !@sam_customer.valid?, which shouldn't happen
    @siteid = @sam_customer.siteid #need to store this separately for a minute because some view logic depends on what's saved in the DB, while other GUI logic relies on instance variable
    @siteid_message = ""
    
    if(@customer_has_active_hosted_server) #note that this takes precedence over any permissions
      @siteid_message = SITEID_ACTIVE_SERVER_MSG
    elsif(!@has_manage_site_id_permission)
      @siteid_message = SITEID_INSUFFICIENT_PERMISSIONS_MSG
    end
    
    @sam_customer = SamCustomer.find(params[:sam_customer][:id])
    
    siteid = params[:sam_customer][:siteid]
    params[:sam_customer][:siteid] = siteid.to_s.strip
	
    prev_siteid = ""
    if (@sam_customer.siteid) 
      prev_siteid = @sam_customer.siteid.to_s.strip
    end
    new_siteid = ""
    if (params[:sam_customer][:siteid]) 
      new_siteid = params[:sam_customer][:siteid].to_s.strip
    end
	
    # the License Manager versions that we allow users to switch to. locking down this way requires code update when new
    # LM versions come out, but seems preferable to allowing freeform input.
    # @available_license_manager_versions is used only for straightforward allowed changes of LM version.
    #   - customer can't simply change to or from version 1 -- other process for that.
    #   - if customer has no current LM version at all, this is not the way to opt them in -- other process for that.
    @available_license_manager_versions = @sam_customer.get_available_license_manager_versions
	
	#logger.info "&&&&&&&&&&&&&&&&&&&&&&&&& #{params[:sam_customer][:cleverid]}"
	#if params[:sam_customer][:cleverid] =~ /^[A-Z0-9]+$/i
	#  logger.info "it is alphanumeric"
	#else
	#  logger.info "it is not alphanumeric"
	#end
	#logger.info "&&&&&&&&&&&&&&&&&&&&&&&&&&&"
    
    # we could get rid of this siteid in use check here and have web api do it, siteid is a unique key in db. leaving it here though, no harm.
    if(params[:sam_customer][:siteid] && is_siteid_in_use(@sam_customer.id, params[:sam_customer][:siteid]))
      logger.warn("Attempted to update sam_customer with site id that is already used by another customer: " + params[:sam_customer][:siteid] + ".  Not allowing.")
      flash[:notice] = SITEID_IN_USE_MSG
      render(:template => "sam_customers/form", :siteid => params[:sam_customer][:siteid], :cleverid => params[:sam_customer][:cleverid])
  	elsif(params[:sam_customer][:siteid] && !params[:sam_customer][:siteid].empty? && (!(params[:sam_customer][:siteid].to_s.strip =~ /^integration/i) && (params[:sam_customer][:siteid].to_s.strip.downcase =~ /[a-z]{1}[0-9]{9}$/).nil?) && (prev_siteid != new_siteid))
  	  flash[:notice] = INVALID_SITEID_LENGTH_MSG
  	  render(:template => "sam_customers/form", :siteid => params[:sam_customer][:siteid], :cleverid => params[:sam_customer][:cleverid])
  	elsif (params[:sam_customer][:cleverid] && !params[:sam_customer][:cleverid].strip.empty? && !(params[:sam_customer][:cleverid].to_s.strip =~ /^[A-Z0-9]+$/i) ) 
	    flash[:notice] = INVALID_CLEVER_ID_MSG
      render(:template => "sam_customers/form", :siteid => params[:sam_customer][:siteid], :cleverid => params[:sam_customer][:cleverid])
    elsif (params[:sam_customer][:cleverid] && !params[:sam_customer][:cleverid].strip.empty? && params[:sam_customer][:siteid].strip.empty?) 
      flash[:notice] = CLEVER_ID_NEEDS_SITE_ID
      render(:template => "sam_customers/form", :cleverid => params[:sam_customer][:cleverid])  
    elsif (params[:sam_customer][:clever_token] && !params[:sam_customer][:clever_token].strip.empty? && params[:sam_customer][:cleverid].strip.empty?) 
      flash[:notice] = CLEVER_TOKEN_NEEDS_CLEVER_ID
      render(:template => "sam_customers/form", :clever_token => params[:sam_customer][:clever_token])
    elsif (params[:sam_customer][:cleverid] && !params[:sam_customer][:cleverid].strip.empty? && params[:sam_customer][:clever_token].strip.empty?) 
      flash[:notice] = CLEVER_ID_NEEDS_CLEVER_TOKEN
      render(:template => "sam_customers/form", :cleverid => params[:sam_customer][:cleverid])
    elsif (params[:sam_customer][:clever_logout_url] && !params[:sam_customer][:clever_logout_url].strip.empty? && (params[:sam_customer][:cleverid].strip.empty? || params[:sam_customer][:clever_token].strip.empty?) ) 
      flash[:notice] = CLEVER_LOGOUT_URL_NEEDS_CLEVER_ID_TOKEN
      if(params[:sam_customer][:clever_token].strip.empty?)
        render(:template => "sam_customers/form", :cleverid => params[:sam_customer][:cleverid])    
      elsif(params[:sam_customer][:cleverid].strip.empty?)
        render(:template => "sam_customers/form", :clever_token => params[:sam_customer][:clever_token])
      else
        render(:template => "sam_customers/form")
      end
    else
      begin
      failure = true
      failure_reasons = Array.new
      sam_customer_attributes = params[:sam_customer]
      if(current_user.hasPermission?(Permission.manage_cleverids))
        if((@sam_customer.cleverid != params[:sam_customer][:cleverid] || @sam_customer.clever_token != params[:sam_customer][:clever_token]) && !params[:sam_customer][:cleverid].empty?) 
          sam_customer_attributes[:clever_verified] = "u"
          sam_customer_attributes[:clever_customer_name] = ""
        elsif(params[:sam_customer][:clever_token].empty? && params[:sam_customer][:cleverid].empty?) 
           sam_customer_attributes[:clever_verified] = "t"
           sam_customer_attributes[:clever_customer_name] = ""   
        end   
      end
      payload = {
                :id => params[:id],
                :method_name => 'update-sam-customer',
                :use_default_name => (params[:sam_customer_use_default_name] == "1" ? 'true' : 'false'),
                :user_id => current_user.id,
                :sam_customer_attributes_json => sam_customer_attributes.to_json
              }
      logger.info "submitting request to update sam customer #{@sam_customer.id.to_s} with payload: #{payload.to_yaml}"
      
      response = CustServServicesHandler.new.dynamic_edit_sam_customer(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_customer'] + @sam_customer.id.to_s)
      
      logger.info "response.type = #{response.type}, code = #{response.code}"
      logger.debug "response = #{response.to_s}"
      if response
        if response.type == 'success'
          logger.debug "request to update sam customer #{@sam_customer.id.to_s} returned success."
          
          if response.body
            begin
              response_data = ActiveSupport::JSON.decode(response.body)
              
              if (response_data['update_statuses'] and !response_data['update_statuses'].empty?)
                logger.error "ERROR: request to Web API call to update sam customer failed: #{response_data['update_statuses']}"
                failure_reasons << response_data['update_statuses'] #not necessarily errors, could be legitimate validation failures like siteID already in use
              else
                logger.info "request to Web API call to update sam customer was successful, sam customer updated!"
                failure = false
              end
              
            rescue ActiveSupport::JSON::ParseError => parse_error
              logger.error "ERROR: invalid JSON response from Web API call to update sam customer: #{parse_error.to_s}"
            end
          else
            # this should not happen. in the absence of any creation_statuses we could call this success, but being safe here
            logger.error "ERROR: no response body from Web API call to update sam customer"
          end # end of if response.body
          
        else
          logger.error "ERROR: request to update sam customer #{@sam_customer.id.to_s} returned failure: #{response.body || String.new}"
          failure_reasons << response.body
        end
      else logger.error "ERROR: no response from Web API call to update sam customer #{@sam_customer.id.to_s}."
      end
      
      if failure
        error_message = "Problem updating SAM customer. "
        failure_reasons.each do |failure_reason|
          error_message += "#{failure_reason}  "
        end
        flash[:notice] = error_message
      else
        flash[:notice] = "Updated #{@sam_customer.name} successfully"
        flash[:msg_type] = "info"
		
		# Call ConnectNow
		retval = {:status => "0", :message => "S3 service is not available"}    
		server = @sam_customer.get_hosted_server
		agent_id = (server.nil? || server.agent.nil?) ? nil : server.agent.id  
		payload = { "subj" => "" , "mode" => ""}
	
		if agent_id.nil?  
			logger.debug(" CSsiteCLECN-3a - agent id is nil - stop")
			puts "      puts CSsiteCLECN-3a - agent id is nil - stop"      
			retval = {:status => "2", :message => "There is no registered agent for this sam server"}          
		else
			response = CustServServicesHandler.new.dynamic_new_request_agent_connect_now(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['agents_web_services'] +
                                                                             "#{agent_id.to_s}" + "/connectNow")
      
			parsed_json = ActiveSupport::JSON.decode(response.body)
			if(!parsed_json["success"].nil?)
				successval = parsed_json["success"]
				if successval
					logger.info(" CSsiteCLECN-3d - successfully agent connect now request")
					puts "      puts CSsiteCLECN-3d - successfully agent connect now request"
					retval = {:status => "1", :message => "Success - Agent is now connecting"}          
				else
					logger.info(" CSsiteCLECN-3e - not successfully in agent connect now - successval = :#{successval}:")
					puts "      puts CSsiteCLECN-3e - not successfully in agent connect now - successval = :#{parsed_json["exception"]}:"
					retval = {:status => "3", :message => parsed_json["exception"]}                              
				end
			end
		end
		################# End of connectnow
		
      end
      
      redirect_to(:action => :show, :id => @sam_customer.id)
      
      rescue Exception => e
        logger.error("ERROR: Problem updating SAM customer: #{e.to_s}  #{e.backtrace.to_s} #{e.message.to_s}")
        flash[:notice] = "Your request could not be processed at this time.  If this problem persists, please contact the system administrator."
        redirect_to(:action => :show, :id => @sam_customer.id)
      end
    end
  end
  
  
  #def destroy
  # taking away destroy method. if someone needs it, we'll have to implement one that uses Web API.
  # not bothering for now though; not used.  - MOD   
  #end
  
  
  def index_seat_pools
    @sam_customer = SamCustomer.find(params[:id])
    @license_counts_by_subcommunity = Subcommunity.find(:all, :select => "s.id, s.name, sum(seat_count) as seat_count",
                                                    :joins => "s inner join seat_pool sp on sp.subcommunity_id = s.id",
                                                    :conditions => ["sp.sam_customer_id = ?", @sam_customer.id],
                                                    :group => "s.name",
                                                    :order => "s.name")
  end
  
  def add_favorite
    #puts "params: #{params.to_yaml}"
    FavoriteSamCustomer.create(:user_id => current_user.id, :sam_customer_id => params[:id])
    redirect_to(:action => :show, :id => params[:id])
  end
  
  def merge_from
  	@sam_customer = SamCustomer.find(params[:id])
  	@active_server_count = SamServer.count(:conditions => ["sam_customer_id = ? and active = true", @sam_customer.id])
  end
  
  def transfer_resources
  	puts "params: #{params.to_yaml}"
  	@state_province_list = [["-any-",0]].concat(StateProvince.find(:all, :conditions => "display_name != ''", :order => "display_name").collect {|sp| [sp.display_name, sp.id]})
  	puts "state province list: #{@state_province_list.to_yaml}"
  	@sam_customer = SamCustomer.find(:first, :select => "sc.*, ca.address_line_1, ca.city_name, ca.zip_code, sp.code",
  								:joins => "sc inner join org on sc.root_org_id = org.id
  										inner join customer_address ca on ca.customer_id = org.customer_id
  										inner join state_province sp on ca.state_province_id = sp.id",
  								:conditions => ["sc.id = ?", params[:id]])
  	post_sc_type = ScEntitlementType.find_by_code(ScEntitlementType.POST_SC_CODE)
  	@entitlements = Entitlement.find(:all, :select => "entitlement.*, product.description", :joins => "inner join product on entitlement.product_id = product.id", :conditions => ["sam_customer_id = ? and sc_entitlement_type_id = ?", @sam_customer.id, post_sc_type.id])
  	@sam_servers = SamServer.find(:all, :select => "ss.*, ssa.address_line_1, ssa.city_name, sp.code", 
  							:joins => "ss inner join sam_server_address ssa on ssa.sam_server_id = ss.id inner join state_province sp on ssa.state_province_id = sp.id",
  							:conditions => ["ss.sam_customer_id = ? and ss.status = 'a'", @sam_customer.id])
  	@users = User.find(:all, :conditions => ["sam_customer_id = ? and user_type = ? and active = true", @sam_customer.id, User.TYPE_CUSTOMER])
  	render(:layout => "new_layout_with_jeff_stuff_scrollable_tables")
  end
  
  def search_by_name_or_id
    logger.info("put: #{params.to_yaml} ")
    logger.info("value of keystring is #{params[:keystring]}")
    @sam_customers = SamCustomer.find_by_keystring(params[:keystring])
    if (@sam_customers.length != 1)
      render(:partial => "search_results", :locals => {:sam_customers => @sam_customers})
    else
      render(:text => sam_customer_path(@sam_customers[0].id))
    end
  end
  
  
  # Search - Used by finder
  # Note: If you change what fields are in the resultset, make sure you also change
  #       "export_sam_customers_to_csv" method so same fields shown in cs site are
  #       in the downloadable csv file.
  def search	
  	#put whole array from sam customers search form into session
    #when a request for csv export comes in, :sam_customer will not be included in the request
    if (params[:sam_customer])
      session[:sam_customer] = params[:sam_customer]
    end
  	payload = params[:sam_customer]
  	@sam_customers = find_sam_customers(payload, FINDER_LIMIT)
	  
    @num_rows_reported = @sam_customers.length

    if(request.xhr?) #if an ajax request..
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end
  end
  
  
    def find_sam_customers(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['sam_customer_finder_web_services'] + "#{limit.to_s}")     
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@sam_customers = []
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
		parsed_json["sam_customers"].each do |e|
			sc = SamCustomer.new
			e.each {|k,v|
				sc[k.to_sym] = v
			}
			@sam_customers << sc
		end
	end
	@ret_customers = @sam_customers
  end  


  def addCustToExportBlacklist
    flash[:msg] = 'Customer ' + params[:ucn] + ' added to export blacklist.'
    @ucnBl = ConvExportBlacklistByUcn.new(:ucn => params[:ucn], :created_at => Time.now, :updated_at => Time.now) 
    @ucnBl.save!
    redirect_to :action => :show, :id => params[:id]
  end

  def removeCustFromExportBlacklist
    flash[:msg] = 'Customer ' + params[:ucn] + ' removed from export blacklist.'
    blRec = ConvExportBlacklistByUcn.find_by_ucn(params[:ucn])
    if !blRec.nil?
      ConvExportBlacklistByUcn.delete(blRec.id)
    end
    redirect_to :action => :show, :id => params[:id]
  end

  def decentralize_dadmin_dashboard
    sam_customer = SamCustomer.find(params[:id])
    sam_customer.decentralize_dadmin_for_dashboard = true
    sam_customer.save!
    flash[:msg] = "District admin Dashboard access for #{sam_customer.name} has been decentralized."
    redirect_to :action => :show, :id => params[:id]
  end

  def restore_dadmin_dashboard
    sam_customer = SamCustomer.find(params[:id])
    sam_customer.decentralize_dadmin_for_dashboard = false
    sam_customer.save!
    flash[:msg] = "District admin Dashboard access for #{sam_customer.name} has been restored."
    redirect_to :action => :show, :id => params[:id]
  end
  
  
  def export_sam_customers_to_csv
    logger.info "EXPORTING SAM Customers CSV, Search params: #{params.to_yaml}"
    
    sam_customers_search_result = SamCustomer.search(session[:sam_customer])
    # server-side CSV always uses default sort, not necessarily current sort in finder display
    
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["Name", "Hosted Site ID", "State", "UCN", "Status", "Fake?", "SC Registration Date", "License Manager Status", "Auth Status", "Update Manager Status", "Update Quizzes As Available"]
      sam_customers_search_result.each do |sam_customer|
        # data row
        csv_row << [sam_customer.name.strip, sam_customer.siteid, sam_customer.state_name, sam_customer.sc_ucn, translateSamCustomerActiveStatus(sam_customer.active), sam_customer.fake, (sam_customer.registration_date ? sam_customer.registration_date.strftime(DATE_FORM) : nil), translateManagerStatus(sam_customer.licensing_status), translateManagerStatus(sam_customer.auth_status), translateManagerStatus(sam_customer.update_manager_status), sam_customer.update_quiz_as_available ]
      end
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => CUSTOMER_FINDER_RESULTS_FILENAME )
  end
  
  
  def use_customer_app_for
    sam_customer = SamCustomer.find(params[:id])
    current_user.sam_customer = sam_customer
    current_user.save
    redirect_to("/")
  end
  
  
  def edit_license_manager_defaults
    unless @current_license_manager_version
      samcSystem = SamcSystem.find(:first)
      @current_license_manager_version = samcSystem.current_license_manager_version
    end
  end
  
  
  def save_license_manager_defaults
    @new_version = params[:license_manager_version]
    
    if @new_version
      samcSystem = SamcSystem.find(:first)
      samcSystem.current_license_manager_version = @new_version
      samcSystem.save!
    end
  end
  
  
  #################
  # AJAX ROUTINES #
  #################
  
  def toggle_favorite
    if (params[:add_favorite] == "true")
      FavoriteSamCustomer.create(:user_id => current_user.id, :sam_customer_id => params[:id])
    else
      FavoriteSamCustomer.delete_all(["user_id = ? and sam_customer_id = ?", current_user.id, params[:id]])
    end
    #render(:partial => "common/favorite_sam_customers", :locals => {:favorite_sam_customers => @current_user.favorite_sam_customer_set})
    render(:partial => "common/favorite_sam_customer_in_dock", :collection => @current_user.favorite_sam_customer_set)
  end
  
  def prepare_for_license_manager #TODO: convert to Web API, SCS-458
	message_sender = SC.getBean("messageSender")
	message_sender.sendPrepLicenseManagerMessage(params[:id].to_i, current_user.id)
	render(:partial => "/common/flash_area", :locals => {:flash_notice => "License Manager preparation is in progress", :flash_type => "info"}, :layout => false)
	rescue Exception => e
		logger.info("ERROR: #{e}")
		render(:partial => "/common/flash_area", :locals => {:flash_notice => "There was a problem preparing this SAM EE Customer for License Manager: #{e}", :flash_type => nil}, :layout => false)
  end
  
  
  def send_updated_server_information  #TODO: convert to Web API, SCS-460
	message_sender = SC.getBean("messageSender")
	message_sender.sendResendServerInformationMessage(params[:server_id].nil? ? nil : params[:server_id].to_i, params[:id].to_i)
	render(:partial => "/common/flash_area", :locals => {:flash_notice => "Your request to send updated server information was successful", :flash_type => "info"}, :layout => false)
	rescue Exception => e
		logger.info("ERROR: #{e}")
		render(:partial => "/common/flash_area", :locals => {:flash_notice => "There was a problem sending updated server information", :flash_type => nil}, :layout => false)
  end
  
  
  
  def scrub_license_manager_data  #TODO: convert to Web API, SCS-461
	  message_sender = SC.getBean("messageSender")
	  message_sender.sendScrubLicenseManagerDataMessage(params[:id].to_i, current_user.id, !params[:scrub_all_entitlements].nil?)
	  render(:partial => "/common/flash_area", :locals => {:flash_notice => "Your request to scrub License Manager data was successful", :flash_type => "info"}, :layout => false)
	rescue Exception => e
		logger.info("ERROR: #{e}")
		render(:partial => "/common/flash_area", :locals => {:flash_notice => "There was a problem scrubbing License Manager data: #{e}", :flash_type => nil}, :layout => false)
  end
  
  
  def activate_license_manager  #TODO: convert to Web API, SCS-455
	sam_customer_service = SC.getBean("samCustomerService")
	sam_customer_service.activateLicenseManagerConversion(params[:id].to_i, current_user.id)
	render(:partial => "/common/flash_area", :locals => {:flash_notice => "License Manager is being activated", :flash_type => "info"}, :layout => false)	
	rescue Exception => e
		logger.info("ERROR: #{e}")
		render(:partial => "/common/flash_area", :locals => {:flash_notice => "There was a problem activating this SAM EE Customer for License Manager: #{e}", :flash_type => nil}, :layout => false)
  end
  
  
  def update_auth_users_table_data
    #logger.debug "getting updated auth user table data for sam customer " + params[:id].to_s
    
    # table has 10 columns, the leftmost 8 (index 0 through 7) of which are sortable. specify the sort fields for those 8 here:
    sortable_field_names = ["au.id", "au.username", "au.type", "au.created_at", "au.updated_at", "au.enabled", "ssu.first_name, ssu.last_name", "ssu.email"]
    
    join_clause = ""
    conditions_clause = " WHERE au.sam_customer_id = #{params[:id]}"
    order_clause = "";
    limit_clause = "";
    offset_clause = "";
    
    includeEmptyAuthUsers = (params[:includeEmptyAuthUsers] == 'true')
    
    if includeEmptyAuthUsers
      join_clause = " LEFT JOIN sam_server_user ssu ON au.id=ssu.auth_user_id"
    else
      join_clause = " INNER JOIN sam_server_user ssu ON au.id=ssu.auth_user_id"
    end
    
    search_string = params[:sSearch]
    if(search_string and !search_string.empty?) #filter param, not required
      # datatable has one filter text box; search across all fields as best we can. note that we can't
      # check if value is numeric and only search certain fields, as username might have numbers.
      # for faster querying, not checking datestamp or boolean fields; it's unlikely someone would 
      # need to filter on them.
      # note that we're only using wildcards at the end of a field, which allows mysql to use its
      # indices.  each of these fields has an index.
      conditions_clause += " AND (au.id = '#{search_string}'" +
                           " OR au.username LIKE '#{search_string}%'" +
                           " OR au.type LIKE '#{search_string}%'" +
                           " OR ssu.first_name LIKE '#{search_string}%'" +
                           " OR ssu.last_name LIKE '#{search_string}%'" +
                           " OR ssu.email LIKE '#{search_string}%')"
    end
    
    if(params[:iSortCol_0] and !params[:iSortCol_0].empty?) #sorting params, not required
      if(sortable_field_names[params[:iSortCol_0].to_i]) #make sure it's a valid sort column; some columns are created at page render
        sort_fields_string = sortable_field_names[params[:iSortCol_0].to_i]
        order_clause = " ORDER BY " + sort_fields_string
        
        if(params[:sSortDir_0] and !params[:sSortDir_0].empty?)
          if('ssu.first_name, ssu.last_name'.eql?(sort_fields_string))
            # boo, have to do an ugly one-off for this compound sort
            order_clause = " ORDER BY ssu.first_name " + params[:sSortDir_0] + ", ssu.last_name " + params[:sSortDir_0]
          else
            order_clause += " " + params[:sSortDir_0]
          end
        end
        
      end
    end
    
    limit_clause = " LIMIT " + (params[:iDisplayLength].to_i).to_s  if(params[:iDisplayLength] and !params[:iDisplayLength].empty?)
    offset_clause = " OFFSET " + params[:iDisplayStart]  if(params[:iDisplayStart] and !params[:iDisplayStart].empty?)
    
    # having duplicate records will actually break the datatable when the JSON is parsed
    auth_users_sql_query = "SELECT DISTINCT au.* FROM auth_user au" +
                           join_clause + 
                           conditions_clause + 
                           order_clause + 
                           limit_clause + 
                           offset_clause
    #logger.debug "looking up auth users by: " + auth_users_sql_query
    @auth_users = AuthUser.find_by_sql(auth_users_sql_query)
    
    # iTotalRecords is the total number of auth users for the specified sam customer - in other
    # words, all the records that would ever be displayed in the table.
    # iTotalDisplayRecords is set to the total number of displayed records (after filter) when 
    # using Scroller plugin, which makes the scroll bar keep correct relative size and position.
    # it is NOT necessarily the number of records displayed in the viewport at a given time.
    # some redundant logic here; using ActiveRecord.count instead of (ActiveRecord.find).length
    # for efficiency.
    
    if includeEmptyAuthUsers
      @iTotalRecords = AuthUser.count(:conditions => "sam_customer_id = #{params[:id]}")
    else
      @iTotalRecords = AuthUser.count(:select => "au.id ", 
                                      :joins => "au " + join_clause, 
                                      :conditions => "au.sam_customer_id = #{params[:id]}", 
                                      :distinct => true)
    end
    
    if(search_string and !search_string.empty?)
      @iTotalDisplayRecords = @auth_users.length
    else #we don't need an else case, just trying to avoid querying for efficiency
      @iTotalDisplayRecords = @iTotalRecords
    end
    
    @sEcho = params[:sEcho].to_i
    render :partial => 'auth_user_table_updates'
  end
  
  
  def resolve_lcd_tasks #TODO: convert to Web API, SCS-462
    flash_type = nil
    flash_notice = "There was a problem resolving the LCD tasks for this SAM EE Customer: "
    message_sender = SC.getBean("messageSender")
    sam_customer = SamCustomer.find(params[:id].to_i)
    batch_process_excluded = sam_customer.lm_conversion_blacklist
    if (batch_process_excluded)
      flash_notice = "This #{SAM_CUSTOMER_TERM} is currently excluded from batch processes."
    else
      flash_notice = "License Count Discrepancy Tasks are being resolved"
      flash_type = "info"
      message_sender.sendResolveLicenseCountDiscrepancyTasksMessage(nil, params[:id].to_i)
    end 	
    render(:partial => "/common/flash_area", :locals => {:flash_notice => flash_notice, :flash_type => flash_type}, :layout => false)	
  rescue Exception => e
  	logger.info("ERROR: #{e}")
  	render(:partial => "/common/flash_area", :locals => {:flash_notice =>  flash_notice + e.to_s, :flash_type => nil}, :layout => false)
  end
  
  
  def toggle_batch_process_inclusion
    if (params[:operation] == "Add")
      logger.info("fuck")
      LmConversionBlacklist.delete_all(["sam_customer_id = ?", params[:id]])
    else
      logger.info("bitch")
      LmConversionBlacklist.create(:sam_customer_id => params[:id])
    end  
    render(:partial => "batch_process_inclusion", :locals => {:batch_process_excluded => (params[:operation] == "Add") ? nil : 1})
  end
  
  
  def update_sam_customers_table
    #puts "params: #{params.to_yaml}"
    #sam_customers = SamCustomer.paginate(:page => params[:page], :order => sam_customers_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
     sam_customers = SamCustomer.paginate(:page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE,
                                          :select => "sc.*, c.ucn as sc_ucn, org.id as org_id, si.description as sc_index, fsc.user_id as favorite",
                                          :joins => "sc inner join org on sc.root_org_id = org.id 
                                                     inner join customer c on org.customer_id = c.id
                                                     inner join customer_address ca on ca.customer_id = c.id
                                                     inner join scholastic_index si on sc.scholastic_index_id = si.id
                                                     left join favorite_sam_customers fsc on (fsc.sam_customer_id = sc.id and fsc.user_id = " + current_user.id.to_s + ")", 
                                          :conditions => ["ca.address_type_id = 5 and ca.state_province_id = ?", @state_province.id], :order => sam_customers_sort_by_param(params[:sort]))
    render(:partial => "sam_customers_table", 
           :locals => {:sam_customer_collection => sam_customers,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :state_id => @state_province.id,
                       :sam_customer_count => sam_customers.total_entries}, :layout => false)
  end
  
  def remove_favorite
    #puts "params: #{params.to_yaml}"
    @sam_customer_id = params[:id]
    FavoriteSamCustomer.delete(params[:favorite_id])
    @favorite_sam_customer_set = current_user.favorite_sam_customer_set
  end
  
  def search_sam_customers
  	puts "params: #{params.to_yaml}"
  	@search_results = SamCustomer.search(params)
  end
  
  protected
  
  def load_sam_customer
    @sam_customer = SamCustomer.find(params[:sam_customer_id]) if !params[:sam_customer_id].nil?
  end
  
  private
  
  def config_sam_customer_pi_chart
    @number_of_customers = SamCustomer.count(:conditions => "fake = false") 
    @number_of_registered_customers = SamCustomer.count(:conditions => "fake = false and registration_date is not null")
    @pct_registered = ((@number_of_registered_customers.to_f / @number_of_customers.to_f) * 100.0).round
    @pct_non_registered = 100 - @pct_registered
  end
  
  def store_state_in_session(sam_customer)
    state = sam_customer.state
    if(!state.nil?)
      session[:state_id] = state.id
    end
    
    return state
  end
  
  def clear_sam_customer_session_variables
    session[:school_pagination_page] = nil
  end
  
  def sam_customers_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "sam_customer_id" then "sc.id"
      when "sam_customer_name" then "sc.name"
      when "auth_status" then "sc.auth_status"
      when "sc_registration_date" then "sc.registration_date desc"
      when "sc_licensing_status" then "sc.licensing_status"
      when "update_manager_status" then "sc.update_manager_status"
      when "sc_index" then "si.description, org.name"
            
      when "sam_customer_id_reverse" then "sc.id desc"
      when "sam_customer_name_reverse" then "sc.name desc"
      when "sc_registration_date_reverse" then "sc.registration_date"
      when "auth_status_reverse" then "sc.auth_status desc"
      when "update_manager_status_reverse" then "sc.update_manager_status desc"
      when "sc_licensing_status_reverse" then "sc.licensing_status desc"
      when "sc_index_reverse" then "si.description desc, org.name"
    
      else "org.name"
    end
  end

  #Keep in sync with same method name in "application_helper"
  #  - Used for csv export
  def translateManagerStatus(status_code)
    case status_code
      when 'n' then "Not Activated"
      when 'p' then "Pending"
      when 'a' then "Enabled"
      when 'd' then "Disabled"
    end
  end
  
  #Keep in sync with same method name in "application_helper"  
  #  - Used for csv export  
  def translateSamCustomerActiveStatus(status)
    status ? "Active" : "Inactive"
  end
  
  def is_siteid_in_use(customer_id, site_id)
    #check to see if there's a customer besides us with this site id
    (SamCustomer.find(:all, :conditions => ["id != ? AND siteid = ?", customer_id, site_id]).length > 0)
  end
end
