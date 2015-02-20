begin
  import 'sami.web.SC'
  import 'java.lang.Integer'
  import 'java.util.HashSet'
  import 'java.util.HashMap'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end

require 'fastercsv'

class SamServersController < SamCustomersController
  include WebAPIShared
  include SaplingsHelper

  before_filter :load_sam_server, :load_view_vars, :except => [:update_table, :request_agent_connect_now]
  before_filter :set_breadcrumb

  layout 'default'
  
  def index
    @sam_customer_id = params[:sam_customer_id].to_i
    @status = params[:status] || 'a'
    logger.info "@status: #{@status}"
    
    # note that get_sam_customer_servers() includes transitioning along with active by default. not passing
    # a sort param as sorting is handled on front end.
    @sam_servers = get_sam_customer_servers(@sam_customer_id, @status)
    
    @widget_list << Widget.new("server_move_history", "Server Move History", nil, 600, 850)
    @widget_list << Widget.new("outdated_components_quizzes", "Show Outdated Components/Quizzes", nil, 600, 850)
    @widget_list << Widget.new("sam_servers", "Sam Server List", nil, 600, 850)

    @prototype_required = true
  end
  
  def edit
    @sam_server = SamServer.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    flash[:notice] = "Couldn't find a SAM Server with ID #{params[:id]}"
    redirect_to(sam_customer_path(@sam_customer.id))
  end
  
  def update
    
    if params.key?(:update_field)
      # wer're doing an AJAX update to some individual field, reached via click-to-edit with JEditable plugin (which generates and submits its 
      # own little form.
      sam_server = SamServer.find(params[:id]) 
      field_to_update = params[:update_field] # a string identifying what single field to update for this SAM server. examples: "uri_scheme", "uri_host"
      
      # we want real nulls in the DB, not empty strings
      sam_server[field_to_update] = ( params[field_to_update].blank? ? nil : params[field_to_update] )
      sam_server.save!
      render :text => params[field_to_update]
    else
      # we're doing a doing a regular update of any number of fields, reached via /sam_servers/<some ID>/edit
      begin
        # no need to convert to Web API here unless someone wants to.  no java bean calls and no SAMC message sending.
        @sam_server = SamServer.find(params[:sam_server][:id])
        @sam_server.auto_resolve_lcd = (params[:sam_server][:auto_resolve_lcd] == "0") ? false : true
        begin
          @sam_server.unignore_guid_date = DateTime.parse("#{params[:sam_server][:unignore_guid_date_part].strip} #{params[:sam_server][:unignore_guid_time_part].strip}")
        rescue Exception
          @sam_server.unignore_guid_date = nil
        end
        @sam_server.ignore_guid = params[:sam_server][:ignore_guid].to_i
        @sam_server.save
        flash[:notice] = "SAM Server successfully updated"
        flash[:msg_type] = "info"
      rescue Exception => e
        logger.info("Problem updating SAM server: #{e.to_s}")
        flash[:notice] = "Your request could not be processed at this time.  If this problem persists, please contact the system administrator."
      ensure
        redirect_to(sam_customer_sam_server_path(@sam_customer.id, @sam_server.id))
      end
    end
    
  end
  
  
  def search    
    #put whole array from search form into session
    #when generating csv, :sam_server will not be included in the request
    if (!params.nil? && params[:sam_server])
      session[:sam_server] = params[:sam_server]
    end
  
	payload = params[:sam_server]
	@sam_servers = find_sam_servers(payload, FINDER_LIMIT)

	@num_rows_reported = @sam_servers.length
	
    # the view needs to know whether to show certain columns based on :flagged_for_deactivation.
    logger.info("rendering for servers finder now")
    has_additional_info = (params[:sam_server][:flagged_for_deactivation] == "1")
    if(request.xhr?) #if an ajax request...
    	render(:partial => "search", :locals => {:has_additional_info => has_additional_info}) #render partial
    else
    	render(:layout => "cs_blank_layout", :locals => {:has_additional_info => has_additional_info}) #otherwise, render other default layout
    end
  end
 
 
  def find_sam_servers(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['sam_server_finder_web_services'] + "#{limit.to_s}")
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@sam_servers = []
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
		parsed_json["sam_servers"].each do |e|
			ss = SamServer.new
			e.each {|k,v|
				ss[k.to_sym] = v
			}
			
			@sam_servers << ss
		end
	end
	@ret_servers = @sam_servers
  end
  
  
  def export_sam_servers_to_csv
    logger.info "Exporting SAM Servers CSV from Finder. Search params: #{params.to_yaml}"
    
    sam_servers_search_result = SamServer.search(session[:sam_server])
    # server-side CSV always uses default sort and default limit (none), not necessarily current sort in finder display
    
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["ID", "Name", "Registered", "Registration Hosted Site ID", "Status", (SAM_CUSTOMER_TERM+" ID"), "Agent ID", (SAM_CUSTOMER_TERM+" Name"), (SAM_CUSTOMER_TERM+" UCN"), "GUID", "State"]
      sam_servers_search_result.each do |sam_server|
        # data row
        csv_row << [sam_server.id, sam_server.name, sam_server.created_at.strftime(DATE_FORM), sam_server["value"], sam_server.get_display_status, sam_server.sam_customer_id, sam_server["agent_id"], sam_server.sam_customer_name.strip, sam_server.ucn, sam_server.guid, sam_server["code"]]
      end
    end
        
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => SERVER_FINDER_RESULTS_FILENAME ) # only finder calls this method these days
  end

  
  def cancelPendingTransactions
    
    user_id = current_user.id
    server_id = params[:sam_server_id]
          
    seat_activities = params[:seat_activities]
    
    # No need to save seat_activities here - it's handled through SeatPoolService.revertSeatActivity()
    # This is just to change conversation statuses
    if( !seat_activities.nil? )
      seat_activities.each do |sa|
        seat_activity = SeatActivity.find(sa)
        conversation_instance = seat_activity.conversation_instance
                    
        if( !conversation_instance.nil? )
          conversation_instance.expire_requests(user_id)
          conversation_instance.save!
        end
      end
    end

    # Conditional is needed for entering this from "Move Servers"
    if(params[:operation])      
        redirect_to :action => :operate_on, :sam_server_id => server_id, :id => server_id, :operation => params[:operation]
    else 
        redirect_to :back
    end
  end
  
  #Cancel pending report requests
  def cancelPendingReportRequests
  	
  	user_id = current_user.id
  	
  	if params[:sam_server_ids]
      sam_server_ids = params[:sam_server_ids]
    elsif params[:id]
      sam_server_ids = Array.new
      sam_server_ids << params[:id].to_i
    end
  	  	
  	server_report_request = ServerReportRequest.find(:all,
  													  :conditions => ["sam_server_id IN (?) and status = 'p'", sam_server_ids])
  	
		server_report_request.each do |report|

			report.status = 'x'
			report.updated_at = Time.now
		
      conversation_instance = report.conversation_instance
      if( !conversation_instance.nil? )
  			 conversation_instance.expire_requests(user_id)
         conversation_instance.save!
      end
      
      report.save!
		end
		
		flash[:msg_type] = 'info'
  	flash[:notice] = "Reports Expired Successfully"
 	
	  # Conditional is needed for entering this from "Move Servers"
 	  if(params[:operation])
        redirect_to :action => :operate_on
    else 
        redirect_to :back
    end
  end
  
  #cancel pending Server Scheduled Update Requests
  def cancelScheduledUpdateRequests
    user_id = current_user.id
    
    if params[:sam_server_ids]
      sam_server_ids = params[:sam_server_ids]
    elsif params[:id]
      sam_server_ids = Array.new
      sam_server_ids << params[:id].to_i
    end
    
    server_scheduled_update_requests = ServerScheduledUpdateRequest.find(:all,
                              :conditions => ["sam_server_id IN (?) and status = 'p'", sam_server_ids])
    
    server_scheduled_update_requests.each do |ssur|
      ssur.cancel_request(user_id)
    end

    flash[:msg_type] = 'info'
    flash[:notice] = "Scheduled Update Requests Cancelled Successfully"
 
    # Conditional is needed for entering this from Move/Deactivate
    if(params[:operation])
      redirect_to :action => :operate_on
    else
      redirect_to :back
    end
    
  end
  
  def show
    @sam_server = SamServer.find(params[:id])
    @sam_customer = @sam_server.sam_customer if @sam_customer.nil?
  	if (@sam_server.server_type != SamServer.TYPE_UNREGISTERED_GENERIC)
  		@license_counts = SamServer.get_all_license_counts(params[:id])
  		logger.info("license_counts: #{@license_counts.to_yaml}")
  	else
  		@license_counts = SeatPool.find_all_by_sam_server_id(@sam_server.id)
  	end
  	@clone_parent = (@sam_server.clone_parent_id.nil?) ? nil : SamServer.find(@sam_server.clone_parent_id)
    @src_quiz_preferences = SrcQuizPreferences.find(:first,
                                                    :conditions => ["sam_server_id = ?", params[:id]])
    sql = <<EOS
      select ac.name, ac.value
      from
        agent a, sam_server ss, agent_component ac
      where 
        a.sam_server_id = ss.id and
        a.id = ac.agent_id and
        ac.name like '%SRCQUIZ%' and
        ss.id = #{params[:id]}
EOS
    @installed_quizzes = SamServer.find_by_sql(sql)
    @widget_list << Widget.new("internal_messages", "Internal Messages", nil, 750, 900)
    @sc_hosting_agreement_info = SamCustomerHostingAgreementInfo.find(:last, :conditions => ["sam_customer_id = ?", @sam_customer.id])
  end
  
  def operate_on
    session[:operation] = params[:operation] if params[:operation]
    @operation = session[:operation] == "1" ? "Move" : "Deactivate"
    
    #Look for the from_landscape param, and set it in the session
    session[:from_landscape_page] = 'true' if('y' == params[:from_landscape])
    
    # to support both individual and multiple move/deactivate, we support a single ID as "sam_server_id", or a collection of IDs as "sam_server_ids"
    if params[:sam_server_ids]
      session[:sam_server_ids] = params[:sam_server_ids]
    elsif params[:sam_server_id]
      session[:sam_server_ids] = Array.new
      session[:sam_server_ids] << params[:sam_server_id]
    end
    
    @sam_server_id_list = ""
    session[:sam_server_ids].each do |ms|
      @sam_server_id_list += ms + ","
    end
    
    @sam_server_id_list.chomp!(",")
    @sam_servers = SamServer.find(:all, :conditions => "id in (#{@sam_server_id_list})")
    @hosted_server_involved = false
    @sam_servers.each {|ss| @hosted_server_involved = true if ss.is_hosted_server?}
    @sam_customer = @sam_servers[0].sam_customer
    
    # get arrays of license tasks similar to in show_deactivate, but for all SamServers in @sam_servers collection.
    @lcd_tasks = Task.find_open_lcd_tasks_for_servers(@sam_servers, nil)
    @lcip_tasks = Task.find_open_lcip_tasks(@sam_customer, nil)
    @plcc_tasks = Task.find_open_plcc_tasks_for_servers(@sam_customer, @sam_servers)
    @seat_activity_ids = SeatActivity.find_incomplete_by_sam_servers(@sam_servers).collect{ |seat_activity| seat_activity.id }
    
    # PLCC tasks, LCD tasks, and Seat Activities are server-specific. LCI tasks are customer-level. flag this server as having
    # license problems for deactivation if there is an open:
    #   - PLCC, LCD, or Seat Activity for the server
    #       OR
    #   - LCI for the customer AND this server has licenses. (if this server has no licenses, its deactivation has no impact on license integrity)
    @license_problems = ( @lcd_tasks.any? || @seat_activity_ids.any? || @plcc_tasks.any? || ( @lcip_tasks.any? && SamServer.servers_have_licenses?(@sam_servers) ) )
    
    # get the information about license count to keep/discard by default for each subcommunity
    @sam_server_deactivation_info = @sam_servers[0].get_deactivation_info if (@operation == "Deactivate")
    
    @progress_bar_support = true
    @scrolling_support = true
  end
  
  
  def show_remediate
    #Look for the from_landscape param, and set it in the session
	if (!params[:from_landscape].nil? && params[:from_landscape] == "y")
      session[:from_landscape_page] = 'true'
    end
	
    @sam_server = SamServer.find(params[:id])
    redirect_to(:action => :index) if @sam_server.nil?
    @sam_customer = @sam_server.sam_customer
    @lcd_tasks = Task.find_open_lcd_tasks(@sam_server, nil)
    @lcip_tasks = Task.find_open_lcip_tasks(@sam_customer, nil)
    @seat_activities = SeatActivity.find_incomplete_by_sam_server(@sam_server)
    @license_problems = (@lcd_tasks.empty? && @lcip_tasks.empty? && @seat_activities.empty?) ? false : true
  end
    
  
  def remediate
    @sam_server = SamServer.find(params[:id])
    raise Exception.new("There are open License Count Discrepancy tasks for this SAM Server") if !Task.find_open_lcd_tasks(@sam_server, nil).empty?
    raise Exception.new("There are open License Count Integrity Problem tasks for this SAM Customer") if !Task.find_open_lcip_tasks(@sam_server.sam_customer, nil).empty?
    seat_pool_count_prefix = "license_count_"
    changing_count_prefix = "change_license_count_"
    seat_pool_count_prefix_length = seat_pool_count_prefix.size
    seat_count_hash = {}
    allocated_pool_hash = {}
    unallocated_pool_hash = {}
    changing_count_hash = {}
    params.each_key do |k|
      if (!k.index(seat_pool_count_prefix).nil? && k.index(seat_pool_count_prefix) == 0)
        seat_pool_id = k.slice(seat_pool_count_prefix_length, k.size).to_i
        seat_count_hash[seat_pool_id] = params[k].to_i
        seat_pool = SeatPool.find(seat_pool_id)
        allocated_pool_hash[seat_pool_id] = seat_pool
        unallocated_pool_hash[seat_pool_id] = SeatPool.find_seat_pool(@sam_server.sam_customer, seat_pool.subcommunity, nil)
      end
    end
    logger.info("seat_count_hash: #{seat_count_hash.to_yaml}")
    logger.info("unallocated_pool_hash: #{unallocated_pool_hash.to_yaml}")
    
    failure = false
    seat_count_hash.each_key do |k|
      
      delta = seat_count_hash[k] - allocated_pool_hash[k].seat_count
      unallocated_pool = unallocated_pool_hash[k]
      logger.info("unallocated pool not nil?: #{!unallocated_pool.nil?}")
      #logger.info("new unallocated pool count: #{(unallocated_pool.seat_count + (delta * -1))}")
      #logger.info("changing?:" + (!params["#{changing_count_prefix}#{k}"].nil?))
      if (!unallocated_pool.nil? && ((unallocated_pool.seat_count + (delta * -1)) >= 0) && (!params["#{changing_count_prefix}#{k}"].nil?))
        allocated_pool = allocated_pool_hash[k]
        subcommunity = allocated_pool.subcommunity
        SeatPool.move_seats(unallocated_pool, allocated_pool, subcommunity, delta, current_user.id)
        # now change the subcommunity info counts as well
        
        # we'll make separate API calls for each subcommunity here, leave the seat_count_hash looping logic alone.
        # note that this differs somewhat from server deactivation and server move.  we don't use a processs 
        # manager for remediate though; no one needs to know the whole seat count hash.
        logger.debug "Attempting to remediate server(s) through Web API call."
        payload = {
          :id => @sam_server.id.to_s,
          :subcommunity_id => subcommunity.id.to_s,
          :method_name => 'remediate-sam-server-subcommunity',
          :new_allocated_count => seat_count_hash[k].to_s,
          :new_enrolled_count => '0'
        }
        
        logger.info "submitting request to deactviate server(s) with payload: #{payload.to_yaml}"
      
        response = CustServServicesHandler.new.dynamic_edit_sam_server(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_server'] + @sam_server.id.to_s)
        
        logger.info "response.type = #{response.type}, code = #{response.code}"
        logger.debug "response = #{response.to_s}"
        
        if response
          if response.type == 'success'
            logger.info "request to Web API to remediate subcommunity #{subcommunity.id} on server #{@sam_server.id.to_s} returned success."
            
            # now zero out the enrollments for this subcommunity
            begin
              SamServerSchoolEnrollment.zero_all_enrollment_counts(@sam_server, subcommunity)
            rescue Exception => exception
              logger.error "ERROR: exception caught trying to zero-out enrollment for subcommunity #{subcommunity.id} on server #{@sam_server.id.to_s}: #{exception}"
              logger.error e.backtrace.to_s
              failure = true
            end
          else
            logger.info "ERROR: non-success response for request to remediate subcommunity #{subcommunity.id} on server #{@sam_server.id.to_s} : #{response.type} : #{response.body}"
            failure = true
          end
        else
          logger.error "ERROR: no response from Web API call to remediate subcommunity #{subcommunity.id} on server #{@sam_server.id.to_s}"
          failure = true
        end

      end
      
      break if failure  #don't keep looping if one of the API or zero_all_enrollment_counts calls fails
    end #end of seat count hash loop
    
    if failure
      flash[:notice] = "Your request could not be processed:&nbsp;&nbsp;#{e}"
      redirect_to(show_remediate_sam_server_path(:id => @sam_server))
    else
      flash[:notice] = "Successfully applied license count changes to server"
      flash[:msg_type] = "info"
      @sam_customer = @sam_server.sam_customer
      redirect_to(show_remediate_sam_server_path(:id => @sam_server))
    end
    
    rescue Exception => e
      logger.error "ERROR: exception caught trying to remediate subcommunities for server #{@sam_server.id.to_s}: #{e}"
      logger.error e.backtrace.to_s
      flash[:notice] = "Your request could not be processed:&nbsp;&nbsp;#{e}"
      redirect_to(show_remediate_sam_server_path(:id => @sam_server))
  end
  
  
  def find_esb_messages_for
  end

  #Update classmapping time to current for QA testing
  def updateClassMappingTime
	@sam_server = SamServer.find(params[:id])
	@sam_server.update_teacher_classmappings_at = Time.now
	@sam_server.save!
    redirect_to :action => :show, :id => params[:id]
  end
  
  # update student classmapping and SAM user sync timestamps
  def update_sam_users_sync_time
    @sam_server = SamServer.find(params[:id])
    @sam_server.update_users_at = nil
    @sam_server.student_classmappings_synced = false
    @sam_server.users_synced = false
    @sam_server.save!
    redirect_to :action => :show, :id => params[:id]
  end
  
  # update student classmapping and SAM user sync timestamps
  def update_customers_sync_time
    @sam_server = SamServer.find(params[:id])
    if(params[:remove])
      @sam_server.customer_set_sync_hour = nil
    else  
      time = params[:sync_time]
      logger.debug(time[:hour].to_s)
      @sam_server.customer_set_sync_hour = time[:hour]
    end  
    @sam_server.save!
    redirect_to :action => :show, :id => params[:id]
  end
    
    # update user subcommunity mapping sync timestamp for codex enrollment
  def update_subcommunity_user_mappings_time
    @sam_server = SamServer.find(params[:id])
    @sam_server.update_subcommunity_user_mappings_at = nil
    @sam_server.save!
    redirect_to :action => :show, :id => params[:id]
  end

  def addServerToExportBlacklist
    flash[:msg] = 'Server ' + params[:id] + ' added to export blacklist.'
    @serverBl = ConvExportBlacklistByServer.new(:sam_server_id => params[:id], :created_at => Time.now, :updated_at => Time.now) 
    @serverBl.save!
    redirect_to :action => :show, :id => params[:id]
  end

  def removeServerFromExportBlacklist
    flash[:msg] = 'Server ' + params[:id] + ' removed from export blacklist.'
    blRec = ConvExportBlacklistByServer.find_by_sam_server_id(params[:id])
    if !blRec.nil?
      ConvExportBlacklistByServer.delete(blRec.id)
    end
    redirect_to :action => :show, :id => params[:id]
  end

  # Request agent to connect immediately
  #  - Debug statement left in for now to help testing with Edison's S3 (was ndt) server
  #  - There s duplicate loggging going on; logger and puts.  logger has issues in BOS,
  #    so puts was added.  Leaving logger in place for production deploy to check if this
  #    same issue with logger is happening in ATL.
  #
  def request_agent_connect_now
    retval = {:status => "0", :message => "S3 service is not available"}    
    logger.debug(" CSsiteRACN -1a PARAMS: ")
    puts "      puts - CSsiteRACN -1a PARAMS: "    
    params.each {|k,v| logger.debug("    * #{k} = #{v}") }
    params.each {|k,v| puts "          puts   * #{k} = #{v}" }    
    server = SamServer.find(params[:id])
    agent_id = (server.nil? || server.agent.nil?) ? nil : server.agent.id  
    logger.debug(" CSsiteRACN-2a - agend_id: " + agent_id.to_s)
    logger.debug(" CSsiteRACN-2b - path: " + '/api/agents/' + agent_id.to_s + "/connectNow")
	logger.debug(" CSsiteRACN-2ba - mode: " + params[:mode])
	if (params[:mode] == 'std_noop') 
	  payload = { "subj" => "" , "mode" => ""}
	elsif (params[:mode] == 'lic_mini_noop')
	  payload = { "subj" => "licensing" , "mode" => "mini"}
	end
    if agent_id.nil?  
      logger.debug(" CSsiteRACN-3a - agent id is nil - stop")
      puts "      puts CSsiteRACN-3a - agent id is nil - stop"      
      retval = {:status => "2", :message => "There is no registered agent for this sam server"}          
    else
      begin
        response = CustServServicesHandler.new.dynamic_new_request_agent_connect_now(request.env['HTTP_HOST'],
                                                                             payload,
                                                                             CustServServicesHandler::ROUTES['agents_web_services'] +
                                                                               "#{agent_id.to_s}" + "/connectNow")
        logger.debug(" CSsiteRACN-3b - response.to_s: #{response.to_s} ")  
        puts "      puts CSsiteRACN-3b - response.to_s: #{response.to_s} "        
        logger.debug(" CSsiteRACN-3c - response.body.to_s: #{response.body.to_s} ")
        puts "      puts CSsiteRACN-3c - response.body.to_s: #{response.body.to_s} "  
        if(response.code == "200")
          parsed_json = ActiveSupport::JSON.decode(response.body)
          if(!parsed_json["success"].nil?)
            successval = parsed_json["success"]
            if successval == "true"
              logger.info(" CSsiteRACN-3d - successfully agent connect now request")
              puts "      puts CSsiteRACN-3d - successfully agent connect now request"
              retval = {:status => "1", :message => "Success - Agent is now connecting"}          
            else
              logger.info(" CSsiteRACN-3e - not successfully in agent connect now - successval = :#{parsed_json["exception"]}:")
              puts "      puts CSsiteRACN-3e - not successfully in agent connect now - successval = :#{parsed_json["exception"]}:"
              if (server.is_Duke_or_later? && server.is_hosted_server?)
                retval = {:status => "3", :message => parsed_json["exception"]}
              else  
                retval = {:status => "3", :message => parsed_json["exception"]}
              end                                
            end
          end
        else
          retval = {:status => "3", :message => "SAMC API call returned #{response.code}"}
        end
      rescue Timeout::Error => e
        retval = {:status => "3", :message => "Timeout occurred during API call. Check logs for specific errors."}  
      end        
    end
    logger.debug(" CSsiteRACN-4a - Done with agents_controller.request_agent_connect_now method ")
    puts "      puts CSsiteRACN-4a - Done with agents_controller.request_agent_connect_now method "    
    logger.debug(" CSsiteRACN-5a - Returning to rhtml page value: #{retval}")
    puts "      puts CSsiteRACN-5a - Returning to rhtml page value: #{retval}"
    retval_as_json = ActiveSupport::JSON.encode(retval)
    render(:text => retval_as_json)
  end

  
  #################
  # AJAX ROUTINES #
  #################
  
  def internal_messages_for
    audit_message_data = AuditMessage.gather_audit_message_data_by_resource_id("S#{params[:sam_server_id]}")
    logger.info("audit_messages are here: #{audit_message_data.to_yaml}")
    logger.info("audit_messages hash has #{audit_message_data.keys.length} entries")
    render(:partial => "internal_messages", :locals => {:audit_message_data => audit_message_data})
  end
  
  
  def get_sam_customer_servers(sam_customer_id, status='a') # status indicates activated vs deactivated servers. only one or the other displayed at a time
    if( status == 'a' )
    	SamServer.find(:all, :select => "ss.*, a.ignore_agent, a.id as agent_id, a.current_command_id, a.updated_at as agent_updated_at, a.next_poll_at", 
               :joins => "ss left outer join agent a on ss.id = a.sam_server_id",
               :conditions =>  ["ss.sam_customer_id = ? and ss.status != 'i'", sam_customer_id] )
    else
      SamServer.find(:all, :select => "ss.*, a.ignore_agent, a.id as agent_id, a.current_command_id, a.updated_at as agent_updated_at, a.next_poll_at", 
               :joins => "ss left outer join agent a on ss.id = a.sam_server_id",
               :conditions =>  ["ss.sam_customer_id = ? and ss.status = 'i'", sam_customer_id] )
    end
  end
  
  def look_up_new_sam_customer
    @new_sam_customer = SamCustomer.find(params[:new_sam_customer_id])
    @new_org = Org.find_summary_details(@new_sam_customer.root_org.id)
    @sam_server_id_list = params[:sam_server_ids]
  end
  
  
  def send_updated_server_information
	message_sender = SC.getBean("messageSender")
	message_sender.sendResendServerInformationMessage(params[:server_id].nil? ? nil : params[:server_id].to_i, params[:id].to_i)
	render(:partial => "/common/flash_area", :locals => {:flash_notice => "Your request to send updated server information was successful", :flash_type => "info"}, :layout => false)
	rescue Exception => e
		logger.info("ERROR: #{e.to_s}")
		render(:partial => "/common/flash_area", :locals => {:flash_notice => "There was a problem sending updated server information.  Please contact a SAMC Administrator.", :flash_type => nil}, :layout => false)
  end   
  
  
  def show_flag_for_transition
    @sam_server = SamServer.find(params[:id])
  end


  def flag_for_deactivation
    logger.info("in flag_for_deactivation")
    # we might have server move or other actions in here one day, keeping extensible
    flag_for_transition(SamServerTransitionRequest.DEACTIVATION_CODE)
  end
  
  def flag_for_transition(transition = SamServerTransitionRequest.DEACTIVATION_CODE)
    message = 'There was a error flagging the server for deactivation. Please contact SAMC development support.'
    
    sam_server = SamServer.find(params[:id])
    if transition == SamServerTransitionRequest.DEACTIVATION_CODE
      if sam_server.flagged_for_deactivation?
        message = 'Server is already flagged for deactivation.'
      else
        if (params[:comment] && !params[:comment].empty?)
          # right now comment is the only input field, and it's required
          comment = params[:comment]
          sam_server.flag_for_deactivation(current_user, comment)
          message = 'Server successfully flagged for deactivation.'
        else
          message = 'A reason must be entered. Server has not been flagged.'
        end
      end
    end
    
    flash[:notice] = message
    flash[:msg_type] = "info"
    redirect_to sam_customer_sam_server_path(sam_server.sam_customer, sam_server)
    
    rescue Exception => e
      message = 'There was a error flagging the server for deactivation. Please contact SAMC development support.'
      logger.info("ERROR: #{e.to_s}")
      flash[:notice] = message
      flash[:msg_type] = "error"
    
    logger.info("leaving flag_for_transition")
    redirect_to sam_customer_sam_server_path(sam_server.sam_customer, sam_server)
  end
  
  
  def move
    logger.debug "Attempting to move server(s), calling shared utility method."
    @sam_server_ids = params[:sam_server_ids]
    move_sam_servers(params) # calling helper method in WebAPIShared, we share it with utilities controller
  end
  
  
  def show_move_history_for
    processes = SamcProcess.find_by_sam_customer_and_process_type(@sam_customer, 'SSM')
    logger.info("the processes are: #{processes.to_yaml}")
    render(:partial => "server_move_history", :locals => {:processes => processes})
  end
 
  def outdated_components_quizzes
  	
  	master_outdated_server_list = [] #holds all servers with outdated components
  	master_updated_server_list = [] #holds all servers with outdated/no components
  	  	
  	sam_servers = SamServer.find(:all, :conditions => ["sam_customer_id = ?", params[:id]])
  	  	
  	sam_servers.each do |ss|

  		if ss.active_non_transitioning? # make sure server is active
  			outdated_saplings = [] #holds all outdated sapling info for a server
  			outdated_server_list = [] #holds server info (id, name, saplings) for all servers w/ outdated components
  			updated_server_list = [] #holds server info (id, name, saplings) for all servers w/ updated components
  			
  	  	agent = ss.agent
    		if(agent) #you need an agent to have agent components
    			agent_components = agent.agent_components
    			
    			if(agent_components) #you need agent components
    				agent_components.each do |ac|
              latest_published_sapling = Sapling.get_latest_published_by_agent_component(ac)
            
              if latest_published_sapling
                latest_published_version = latest_published_sapling.version
                if SaplingsHelper.compare_release_versions(ac.value, latest_published_version) < 0
                  outdated_saplings << { "sapling_name" => ac.name, 
                                         "sapling_version" => ac.value,
                                         "max_sapling_version" => latest_published_version } # add sapling info hash to list
                end
              end
            end
    			end
    		end
	
			#as long as there were outdated saplings...
			if(!outdated_saplings.empty?)
				outdated_server_list = [] #clear the list from previous info
				#add the server info
				outdated_server_list << ss.id
				outdated_server_list << ss.name
				outdated_server_list << outdated_saplings
				#add the server to the master list
				master_outdated_server_list << outdated_server_list
			#no saplings were out of date
			else
				updated_server_list = [] #outdated components exist
				#add the server info
				updated_server_list << ss.id
				updated_server_list << ss.name
				#add the server info
				master_updated_server_list << updated_server_list
			end
		end
		
   	end
	
  	render(:partial => "component_quiz_history", :locals => {:outdated_server_list => master_outdated_server_list,
  															 :updated_server_list => master_updated_server_list})

  end


  def deactivate
    logger.debug "Attempting to deactivate server(s), calling shared utility method."
    @sam_server_ids = params[:sam_server_ids]
    deactivate_sam_servers(params) # calling helper method in WebAPIShared, we share it with utilities controller
  end
  
  
  def edit_server_name
    @server = SamServer.find( params[:id] )
  end
  
  def save_server_name
    # call Web API to update the server. we're only updating the name here
    
    @server = SamServer.find(params[:serverId])
    unless @server
      logger.error("couldn't find server for requested ID, doing nothing: #{params[:serverId]}")
      return
    end
    
    logger.info("in sam_servers_controller.save_server_name " +
      "   serverId = " + params[:serverId] +
      "   old server name = " + @server.name +
      "   new server name = " + params[:server_name])
    
    sam_server_updates_hash = Hash.new
    sam_server_updates_hash["name"] = params[:server_name]
    
    logger.debug "sam_server_updates_hash is: #{sam_server_updates_hash.to_yaml}"
    
    #flatten to JSON string for HTTP requst, we'll unpack on the other side
    sam_server_updates_json = sam_server_updates_hash.to_json
    
    failure = true
    failure_reasons = Array.new
    payload = {
      :id => @server.id.to_s,
      :method_name => 'update-sam-server',
      :sam_server_updates_json => sam_server_updates_json
    }
    
    logger.info "submitting request to update server #{@server.id.to_s} with payload: #{payload.to_yaml}"
    response = CustServServicesHandler.new.dynamic_edit_sam_server(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_server'] + @server.id.to_s)
    
    logger.info "response.type = #{response.type}, code = #{response.code}"
    logger.debug "response = #{response.to_s}"
    
    if response
      if response.type == 'success' #doesn't mean server updated necessarily, only that request was handled successfully. may have been validation failures 
        logger.info "request to Web API to update server #{@server.id.to_s} returned success, checking validation failures..."
        
        if response.body
          begin
            response_data = ActiveSupport::JSON.decode(response.body)
            
            validation_failure_reasons = response_data['validation_failure_reasons'] #we tried to change something that the business/validation logic in the API didn't like 
            if (validation_failure_reasons and !validation_failure_reasons.empty?)
              validation_failure_reasons.each do |failure_reason|
                failure_reasons << failure_reason  unless failure_reasons.include?(failure_reason) #don't need duplicates
              end
              logger.error "ERROR: request to Web API call to update server #{@server.id.to_s} failed: #{validation_failure_reasons}"
            else # validation_failure_reasons being empty or missing completely both mean success
              logger.info "request to Web API call to update server #{@server.id.to_s} was successful, no validation failures!"
              failure = false
            end
            
          rescue ActiveSupport::JSON::ParseError => parse_error
            logger.error "ERROR: invalid JSON response from Web API call to update server #{@server.id.to_s}"
          end
        else logger.error "ERROR: no response body from Web API call to update server #{@server.id.to_s}"
        end
        
      else
        logger.info "ERROR: non-success response for request to update server #{@server.id.to_s} : #{response.type} : #{response.body}"
        failure_reasons << response.body
      end # end of if response.type == 'success'
    else logger.error "ERROR: no response from Web API call to update server #{@server.id.to_s}"
    end
    
    if failure
      # not much we can do here, this shouldn't fail and there's no flash/redirect in place right now,
      # can be implemented if needed.
      failure_reasons.each do |failure_reason|
        logger.error "could not update sam server as requested: #{failure_reason}"
      end
    else
      @server.name=params[:server_name] # make the view refresh
    end
    
    rescue Exception => exception
      logger.info("ERROR: #{exception.to_s}")
  end  
  
  
  def cancel_deactivation_request
    SamServer.find(params[:id]).cancel_deactivation_request
    redirect_to :action => :show, :id => params[:id]
  end
  
  def revoke_deactivation_request
    SamServer.find(params[:id]).revoke_deactivation_request
    redirect_to :action => :show, :id => params[:id]
  end
  
  def update_sam_server_users_table_data
    #logger.debug "getting updated sam server user table data for sam customer " + params[:id].to_s
    
    # table has 12 columns, sortable on all of them:
    sortable_field_names = ["id", "type", "created_at", "updated_at", "auth_user_id", "first_name", "last_name", "email", "username", "password", "enabled", "district_user_id"]
    
    conditions_clause = " WHERE sam_server_id = #{params[:id]}"
    order_clause = "";
    limit_clause = "";
    offset_clause = "";
    
    search_string = params[:sSearch]
    if(search_string and !search_string.empty?) #filter param, not required
      # datatable has one filter text box; search across all fields as best we can. note that we can't
      # check if value is numeric and only search certain fields, as username might have numbers.
      # for faster querying, not checking datestamp or boolean fields; it's unlikely someone would 
      # need to filter on them.
      # note that we're only using wildcards at the end of a field, which allows mysql to use its
      # indices.  each of these fields has an index.
      conditions_clause += " AND (id = '#{search_string}'" +
                           " OR type LIKE '#{search_string}%'" +
                           " OR auth_user_id = '#{search_string}'" +
                           " OR first_name LIKE '#{search_string}%'" +
                           " OR last_name LIKE '#{search_string}%'" +
                           " OR email LIKE '#{search_string}%'" +
                           " OR username LIKE '#{search_string}%'" +
                           " OR password LIKE '#{search_string}%'" +
                           " OR district_user_id LIKE '#{search_string}%')"
    end
    
    if(params[:iSortCol_0] and !params[:iSortCol_0].empty?) #sorting params, not required
      if(sortable_field_names[params[:iSortCol_0].to_i]) #make sure it's a valid sort column; some columns are created at page render
        sort_fields_string = sortable_field_names[params[:iSortCol_0].to_i]
        order_clause = " ORDER BY " + sort_fields_string
        
        if(params[:sSortDir_0] and !params[:sSortDir_0].empty?)
          order_clause += " " + params[:sSortDir_0]
        end
      end
    end
    
    limit_clause = " LIMIT " + (params[:iDisplayLength].to_i).to_s  if(params[:iDisplayLength] and !params[:iDisplayLength].empty?)
    offset_clause = " OFFSET " + params[:iDisplayStart]  if(params[:iDisplayStart] and !params[:iDisplayStart].empty?)
    
    # having duplicate records will actually break the datatable when the JSON is parsed
    sam_server_users_sql_query = "SELECT DISTINCT * FROM sam_server_user" +
                           conditions_clause + 
                           order_clause + 
                           limit_clause + 
                           offset_clause
    #logger.debug "looking up sam server users by: " + sam_server_users_sql_query
    @sam_server_users = SamServerUser.find_by_sql(sam_server_users_sql_query)
    
    # iTotalRecords is the total number of users for the specified sam server - in other
    # words, all the records that would ever be displayed in the table.
    # iTotalDisplayRecords is set to the total number of displayed records (after filter) when 
    # using Scroller plugin, which makes the scroll bar keep correct relative size and position.
    # it is NOT necessarily the number of records displayed in the viewport at a given time.
    # some redundant logic here; using ActiveRecord.count instead of (ActiveRecord.find).length
    # for efficiency.
    
    @iTotalRecords = SamServerUser.count(:conditions => "sam_server_id = #{params[:id]}")
    
    if(search_string and !search_string.empty?)
      @iTotalDisplayRecords = @sam_server_users.length
    else #we don't need an else case, just trying to avoid querying for efficiency
      @iTotalDisplayRecords = @iTotalRecords
    end
    
    @sEcho = params[:sEcho].to_i
    render :partial => 'sam_server_user_table_updates'
  end
  
  
  def reset_sam_district_admin_password
    message = 'There was an error resetting the district admin password. Please contact SAMC development support.'
    sam_server = SamServer.find(params[:id])
    if sam_server.reset_request_pending?(SamServerResetRequest.DADMIN_PASSWORD_CODE)
      message = 'A request to reset the district admin password is already pending.'
    else
      sam_server.request_reset(current_user, SamServerResetRequest.DADMIN_PASSWORD_CODE)
      message = 'Request to reset the district admin password has been received.'
    end
    
    #render(:partial => "/common/flash_area", :locals => {:flash_notice => message, :flash_type => "info"}, :layout => false)
    
    flash[:notice] = message
    redirect_to :back
    
    rescue Exception => e
      message = 'There was an error resetting the district admin password. Please contact SAMC development support.'
      logger.info("ERROR: #{e.to_s}")
    
      #render(:partial => "/common/flash_area", :locals => {:flash_notice => message, :flash_type => "error"}, :layout => false)
      
      flash[:notice] = message
      redirect_to :back
  end


  def reset_sam_hosted_terms_acceptance
    message = 'There was an error resetting the hosted terms acceptance. Please contact SAMC development support.'
    sam_server = SamServer.find(params[:id])
    if sam_server.reset_request_pending?(SamServerResetRequest.HOSTED_TERMS_ACCEPTANCE_CODE)
      message = 'A request to reset the hosted terms acceptance is already pending.'
    else
      sam_server.request_reset(current_user, SamServerResetRequest.HOSTED_TERMS_ACCEPTANCE_CODE)
      message = 'Request to reset the hosted terms acceptance has been received.'
    end
    
    #render(:partial => "/common/flash_area", :locals => {:flash_notice => message, :flash_type => "info"}, :layout => false)
    
    flash[:notice] = message
    redirect_to :back
    
    rescue Exception => e
      message = 'There was an error resetting the hosted terms acceptance. Please contact SAMC development support.'
      logger.info("ERROR: #{e.to_s}")
    
      #render(:partial => "/common/flash_area", :locals => {:flash_notice => message, :flash_type => "error"}, :layout => false)
    
      flash[:notice] = message
      redirect_to :back
  end
  
  
  def flag_for_transition(transition = SamServerTransitionRequest.DEACTIVATION_CODE)
    message = 'There was an error flagging the server for deactivation. Please contact SAMC development support.'
    
    sam_server = SamServer.find(params[:id])
    if transition == SamServerTransitionRequest.DEACTIVATION_CODE
      if sam_server.flagged_for_deactivation?
        message = 'Server is already flagged for deactivation.'
      else
        if (params[:comment] && !params[:comment].empty?)
          # right now comment is the only input field, and it's required
          comment = params[:comment]
          sam_server.flag_for_deactivation(current_user, comment)
          message = 'Server successfully flagged for deactivation.'
        else
          message = 'A reason must be entered. Server has not been flagged.'
        end
      end
    end
    
    flash[:notice] = message
    flash[:msg_type] = "info"
    redirect_to sam_customer_sam_server_path(sam_server.sam_customer, sam_server)
    
    rescue Exception => e
      message = 'There was an error flagging the server for deactivation. Please contact SAMC development support.'
      logger.info("ERROR: #{e.to_s}")
      flash[:notice] = message
      flash[:msg_type] = "error"
    
    redirect_to sam_customer_sam_server_path(sam_server.sam_customer, sam_server)
  end
  
  
  
  protected
  
  def load_sam_server
    @sam_server = SamServer.find(params[:sam_server_id]) if params[:sam_server_id]
  end
  
  def set_breadcrumb
    @site_area_code = SAM_SERVERS_CODE
  end
  
  private
  
  def load_view_vars
    @prototype_required = true
  end
  
end
