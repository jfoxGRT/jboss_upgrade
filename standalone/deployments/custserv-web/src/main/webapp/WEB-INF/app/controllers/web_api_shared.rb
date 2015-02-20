module WebAPIShared
    
  def deactivate_sam_servers(params)
    logger.debug "Attempting to deactivate server(s) with Web API call from shared method."
    @failure = false
    @error_descriptions = []
    @process_token = nil
    @process = nil
    @process_threads = nil
    server_ids = params[:sam_server_ids].split(',').collect{|s| s.strip}.collect{|t| t.to_i}
    puts "server_ids: #{server_ids.to_yaml}"
    
    seat_pool_count_prefix = "license_count_"
    seat_pool_count_prefix_length = seat_pool_count_prefix.size
    seat_count_hash = Hash.new
    params.each_key do |k|
      if (!k.index(seat_pool_count_prefix).nil? && k.index(seat_pool_count_prefix) == 0)
        seat_pool_id = k.slice(seat_pool_count_prefix_length, k.size)
        seat_count_hash[seat_pool_id] = params[k]
      end
    end
    
    logger.debug "seat_count_hash is: #{seat_count_hash.to_yaml}"
    
    # only setting the seat_count_hash for applicable license_counts_option. discard license_count_<seat_pool_id> 
    # params are submitted from the view for the other options. license count dispositions:
    #   0 = keep all             1 = discard all
    #   2 = custom selection     3 = discard up to virtual count, keep remainder (default)
    license_count_disposition = params[:license_counts_option] || '0' # default if not provided; batch deactivate won't have params[:license_counts_option] 
    seat_count_json = seat_count_hash.to_json  if license_count_disposition.to_i > 1
    #flatten to JSON string for HTTP requst, we'll unpack on the other side
    
    # with the introduction of Web API, we're handling multiple server deactivations by looping and submitting 
    # individual requests. each process will have only one resource from now on.
    server_ids.each do |server_id|
      payload = {
        :id => server_id,
        :user_id => current_user.id,
        :method_name => 'deactivate-sam-server',
        :license_count_disposition => license_count_disposition,
        :comment => params[:comment],
        :seat_count_json => seat_count_json
      }
      
      logger.info "submitting request to deactivate server(s) with payload: #{payload.to_yaml}"
      response = CustServServicesHandler.new.dynamic_edit_sam_server(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_server'] + server_id.to_s)
      
      logger.info "response.type = #{response.type}, code = #{response.code}"
      logger.debug "response = #{response.to_s}"
      response_data = nil
      @failure = true
      if response
        if response.type == 'success' #doesn't mean server deactivated ok, only that request was handled successfully
          logger.info "request to Web API to deactivate server #{server_id} returned success, checking validation failures..."
          
          if response.body
            begin
              response_data = ActiveSupport::JSON.decode(response.body)
              
              validation_failure_reasons = response_data['validation_failure_reasons'] #not necessarily errors, could be legitimate validation failures like open PLCCs
              if (validation_failure_reasons and !validation_failure_reasons.empty?)
                validation_failure_reasons.each do |failure_reason|
                  @error_descriptions << failure_reason  unless @error_descriptions.include?(failure_reason) #don't need duplicates
                end
                logger.error "ERROR: request to Web API call to deactivate server #{server_id} failed: #{validation_failure_reasons}"
              else
                logger.info "request to Web API call to deactivate server #{server_id} was successful, no validation failures!"
                @failure = false
                @process_token = response_data['process_token'] # don't think there's much we can do if process_token isn't in response, let it break so someone sees it
                if(!@process_token.nil?)
                  logger.info("the process token is: #{@process_token}")
                  @process = SamcProcess.find_by_process_token(@process_token)
                  #it seems to take a while for the process record to be written to the db. lets give it 5 seconds to get in the db before we tell the user "can't help you"
                  if(@process.nil?)
                    logger.info("Process record may not have been written to the db, waiting a bit to see if it shows up.")
                    sleep(5)
                    @process = SamcProcess.find_by_process_token(@process_token)
                  end  
                  if(!@process.nil?)
                    logger.info("the process id is: #{@process.id}")
                    @process_threads = ProcessMessageResponse.find_incomplete_by_group(@process.id)
                    if(!@process_threads.nil?)
                      logger.info("the process threads are: #{@process_threads.to_yaml}")
                    else
                      logger.info("Process threads cannot be obtained.")
                    end
                  else
                    logger.info("Processes cannot be obtained.")
                  end
                else
                  logger.info("Process token cannot be obtained.")
                end
              end
              
            rescue ActiveSupport::JSON::ParseError => parse_error
              logger.error "ERROR: invalid JSON response from Web API call to deactivate server #{server_id}"
            end
          else logger.error "ERROR: no response body from Web API call to deactivate server #{server_id}"
          end
          
        else
          logger.info "ERROR: non-success response for request to deactivate server #{server_id} : #{response.type} : #{response.body}"
          @error_descriptions << response.body
        end # end of if response.type == 'success'
      else logger.error "ERROR: no response from Web API call to deactivate server #{server_id}"
      end
    end # end of loop over server_ids
  end
  
  
  def move_sam_servers(params)
    logger.debug "Attempting to move server(s) with Web API call from shared method."
    
    @failure = false
    @error_descriptions = []
    @process_token = nil
    @process = nil
    @process_threads = nil
    server_ids = params[:sam_server_ids].split(',').collect{|s| s.strip}.collect{|t| t.to_i}
    puts "server_ids: #{server_ids.to_yaml}"
    
    # with the introduction of Web API, we're handling multiple server moves by looping and submitting 
    # individual requests. each process will have only one resource from now on.
    server_ids.each do |server_id|
      payload = {
        :id => server_id,
        :user_id => current_user.id,
        :method_name => 'move-sam-server',
        :new_sam_customer_id => params[:new_sam_customer_id]
      }
      
      logger.info "submitting request to move server(s) with payload: #{payload.to_yaml}"
      
      response = CustServServicesHandler.new.dynamic_edit_sam_server(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_sam_server'] + server_id.to_s)
      
      logger.info "response.type = #{response.type}, code = #{response.code}"
      logger.debug "response = #{response.to_s}"
      response_data = nil
      @failure = true
      if response
        if response.type == 'success' #doesn't mean server moved ok, only that request was handled successfully
          logger.info "request to Web API to move server #{server_id} returned success, checking validation failures..."
          
          if response.body
            begin
              response_data = ActiveSupport::JSON.decode(response.body)
              
              validation_failure_reasons = response_data['validation_failure_reasons'] #not necessarily errors, could be legitimate validation failures like open PLCCs
              if (validation_failure_reasons and !validation_failure_reasons.empty?)
                validation_failure_reasons.each do |failure_reason|
                  @error_descriptions << failure_reason  unless @error_descriptions.include?(failure_reason) #don't need duplicates
                end
                logger.error "ERROR: request to Web API call to move server #{server_id} failed: #{validation_failure_reasons}"
              else
                logger.info "request to Web API call to move server #{server_id} was successful, no validation failures!"
                @failure = false
                @process_token = response_data['process_token'] # don't think there's much we can do if process_token isn't in response, let it break so someone sees it
                logger.info("the process token is: #{@process_token}")
                @process = SamcProcess.find_by_process_token(@process_token)
                logger.info("the process id is: #{@process.id}")
                @process_threads = ProcessMessageResponse.find_incomplete_by_group(@process.id)
                logger.info("the process threads are: #{@process_threads.to_yaml}")
              end
              
            rescue ActiveSupport::JSON::ParseError => parse_error
              logger.error "ERROR: invalid JSON response from Web API call to move server #{server_id}"
            end
          else logger.error "ERROR: no response body from Web API call to move server #{server_id}"
          end
          
        else
          logger.error "ERROR: non-success response for request to move server #{server_id} : #{response.type} : #{response.body}"
          @error_descriptions << response.body
        end # end of if response.type == 'success'
      else logger.error "ERROR: no response from Web API call to move server #{server_id}"
      end
    end # end of loop over server_ids
  end
  
end