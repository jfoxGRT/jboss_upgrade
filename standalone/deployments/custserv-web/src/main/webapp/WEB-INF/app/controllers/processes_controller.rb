require 'fastercsv'
class ProcessesController < ApplicationController  

  layout 'cs_layout'

  def search
    #put whole array from search form into session
    #when generating csv, :processes will not be included in the request
    if (!params.nil? && params[:processes])
      session[:processes] = params[:processes]
    end

  	payload = params[:processes]
  	@process_messages = find_process_messages(payload, FINDER_LIMIT)
	
    @num_rows_reported = @process_messages.length

    if(request.xhr?) #if an ajax request...
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end
 end
  
  def find_process_messages(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['process_finder_web_services'] + "#{limit.to_s}")
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@process_messages = []
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
		parsed_json["process_messages"].each do |pm|
			p = SamcProcess.new
			pm.each {|k,v|
				puts k
				puts v
				p[k.to_sym] = v
			}
			
			@process_messages << p
		end
	end
	@ret_process_messages = @process_messages
  end


  def export_processes_search_to_csv
    logger.info "EXPORTING CSV"
     
  	payload = session[:processes]
  	@processes_search_results = find_process_messages(payload, -1)
	
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["ID", "Type", "SAM Customer ID", "SAM Customer Name", "SAM Server ID", "Completed", "Started", "Percentage Complete", "User E-mail"]
      @processes_search_results.each do |processes|
        #populating each data row with database fields
        csv_row << [processes.id, processes.process_type_code, processes.sam_customer_id, processes.sam_customer_name, processes.sam_server_id, processes.completed_at.strftime(DATE_FORM), processes.started_at.strftime(DATE_FORM), processes.pct_complete, processes["user_email"]]
      end
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => PROCESS_FINDER_RESULTS_FILENAME)
  end 

end

