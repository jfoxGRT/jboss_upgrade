class SamServerReportRequestsController < SamServersController

  layout 'default'

  def index
  	if @sam_server.nil? 
  		@sam_server = SamServer.find(params[:id])
  	end
    @sam_customer = @sam_server.sam_customer
        
# #   @server_report_requests = ServerReportRequest.paginate(:page => params[:page],
# #                                                          :conditions => ["sam_server_id = ?", @sam_server.id],
# #                                                          :order => "created_at desc",
# #                                                          :per_page => PAGINATION_ROWS_PER_PAGE)
    @server_report_requests = ServerReportRequest.load_four_hundred_records(@sam_server.id).paginate(:page => params[:page],
                                                                                                     :per_page => PAGINATION_ROWS_PER_PAGE)
    
    #create hash of server report request ids & async file upload IDs
    @async_file_uploads = Hash.new
    @conversation_instance_ids = Hash.new
    
    @server_report_requests.each do |srr|
        async_file_upload = AsyncFileUpload.find(:first,
                                                 :conditions => ["server_report_request_id = ?", srr.id])
        @conversation_instance_ids[srr.id] = srr.conversation_instance_id
        @async_file_uploads[srr.id] = async_file_upload
    end    
    
  end

  #################
  # AJAX ROUTINES #
  #################

  def update_report_requests_table
    @sam_customer = @sam_server.sam_customer
    logger.info(" *****************  update_report_requests_table for sam server #{@sam_server.id}")
   # #@server_report_requests = ServerReportRequest.paginate(:page => params[:page],
   # #                                                       :conditions => ["sam_server_id = ?", @sam_server.id],
   # #                                                       :order => "created_at desc",
   # #                                                       :per_page => PAGINATION_ROWS_PER_PAGE)
   # #
   # #@server_report_requests = get_server_report_requests(params[:sort])
    @server_report_requests = ServerReportRequest.load_four_hundred_records(@sam_server.id).paginate(:page => params[:page],
                                                                                                    :per_page => PAGINATION_ROWS_PER_PAGE)

    #create hash of server report request ids & async file upload IDs
     @async_file_uploads = Hash.new
     @conversation_instance_ids = Hash.new
     
     @server_report_requests.each do |srr|
         async_file_upload = AsyncFileUpload.find(:first,
                                                  :conditions => ["server_report_request_id = ?", srr.id])
         @conversation_instance_ids[srr.id] = srr.conversation_instance_id
         @async_file_uploads[srr.id] = async_file_upload
     end    
                                                                                                     
    render(:partial => "report_requests_table",
               :locals => {:report_requests_collection => @server_report_requests,
                           :status_indicator => params[:status_indicator],
                           :update_element => params[:update_element],
                           :async_file_uploads => @async_file_uploads, 
                           :conversation_instance_ids => @conversation_instance_ids,
						   :sam_server => @sam_server}, :layout => false)
  end

  def get_server_report_requests(sortby)
   # #ServerReportRequest.paginate(:page => params[:page],
   # #                                                     :conditions => ["sam_server_id = ?", @sam_server.id],
   # #                                                     :order => server_report_requests_sort_by_param(sortby),
   # #                                                     :per_page => PAGINATION_ROWS_PER_PAGE)
     ServerReportRequest.load_four_hundred_records(@sam_server.id).paginate(:page => params[:page],
                                                                                                    :per_page => PAGINATION_ROWS_PER_PAGE)
  end

  def server_report_requests_sort_by_param(sortby)
    case sortby
      when "id" then "id asc"
      when "created_at" then "created_at asc"
      when "sam_server_id" then "sam_server_id asc"
      when "report_type_id" then "report_type_id asc"
      when "cohort_type" then "cohort_type asc"
      when "user_id" then "user_id asc"
      when "date_range" then "date_range asc"
      when "expiration_date" then "expiration_date asc"
      when "status" then "status asc"

      when "id_reverse" then "id desc"
      when "created_at_reverse" then "created_at desc"
      when "sam_server_id_reverse" then "sam_server_id desc"
      when "report_type_id_reverse" then "report_type_id desc"
      when "cohort_type_reverse" then "cohort_type desc"
      when "user_id_reverse" then "user_id desc"
      when "date_range_reverse" then "date_range desc"
      when "expiration_date_reverse" then "expiration_date desc"
      when "status_reverse" then "status desc"
    end
  end
  
  def show
    @sam_server_report_request = ServerReportRequest.find(params[:id])
    #create hash of server report request ids & async file upload IDs
        @async_file_uploads = Hash.new
        @conversation_instance_ids = Hash.new
        
       
            async_file_upload = AsyncFileUpload.find(:first, :conditions => ["server_report_request_id = ?", @sam_server_report_request.id])
            @conversation_instance_ids[@sam_server_report_request.id] = @sam_server_report_request.conversation_instance_id
            @async_file_uploads[@sam_server_report_request.id] = async_file_upload
        
  end

  def search
    if (params[:sam_server_report_request])
        session[:sam_server_report_request] = params[:sam_server_report_request]
    end
    @server_id = params[:server_report_request][:id]
  	payload = params[:server_report_request]
  	@server_report_requests = find_report_request(payload, FINDER_LIMIT)
  	
    @num_rows_reported = @server_report_requests.length
    render(:partial => "search")
  end
  
  def find_report_request(payload, limit)
  response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
          payload,
          CustServServicesHandler::ROUTES['request_report_finder_web_services'] + "#{limit.to_s}")
  parsed_json = ActiveSupport::JSON.decode(response.body)
  @server_report_requests = []
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
	  parsed_json["server_report_requests"].each do |e|
	  au = ServerReportRequest.new
			  e.each {|k,v|
		  au[k.to_sym] = v
	  }
	  
	  @server_report_requests << au
	  end
  end	  
		
@ret_customers = @server_report_requests
end

end
