begin
  import 'sami.web.SC'
  import 'java.lang.Integer'
  import 'java.util.HashSet'
  import 'sami.scholastic.api.process.resource_transfer.ResourceTransferPackage'
  import 'sami.scholastic.api.process.SamcProcessPackage'
  import 'sami.scholastic.api.process.resource_transfer.EEntitlementMoverValidationStatus'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end

require 'fastercsv'

class EntitlementsController < SamCustomersController
  
  before_filter :set_breadcrumb

  layout "default"

def index
  #@entitlements = Entitlement.paginate(:page => params[:page], :select => "entitlement.*", 
  #                   :per_page => 12,
  #                   :joins => "inner join sc_entitlement_type on entitlement.sc_entitlement_type_id = sc_entitlement_type.id inner join product on entitlement.product_id = product.id",
  #                   :conditions => ["sam_customer_id = ?", @sam_customer.id], :order => "id desc")
  #@entitlements = Entitlement.index(@sam_customer)
	if (!params[:product_id].nil?)
		@product = (params[:product_id] == "All" ? nil : Product.find(params[:product_id]))
		if (!params[:status].nil?)
			@status = params[:status]
			@entitlements = Entitlement.index(@sam_customer, params[:product_type], @product, params[:status])
			@show_limit_msg = (@entitlements.length == 300) ? true : false
			# render(:partial => "sam_customer_entitlements_info", :locals => {:entitlement_collection => @entitlements,
			#                        :status => @status,
			#                             :product => @product,
			#                             :status_indicator => "entitlements_loading_indicator",
			#                             :update_element => "sam_customer_entitlements_table",
			#                             :sam_customer_id => @sam_customer.id,
			#                             :show_limit_msg => @show_limit_msg})
			respond_to do |format|
			#  format.js {render(:text => "yo")}
			#  format.html {render(:text => "hey")}
				format.js { render(:partial => "sam_customer_entitlements_info", :locals => {:entitlement_collection => @entitlements,
				                          :status => @status,
				                          :product => @product,
				                          :status_indicator => "entitlements_loading_indicator",
				                          :update_element => "sam_customer_entitlements_table",
				                          :sam_customer_id => @sam_customer.id,
				                          :show_limit_msg => @show_limit_msg})
				                        }
			end
		end
	else
		#@license_products = Product.all(:conditions => "sam_server_product = true", :order => "description")
		#@service_products = Product.all(:conditions => "sam_server_product = false", :order => "description")
    @license_products = []
    @service_products =[]
		@all_products = Product.all(:order => "description")
    @all_products.each do |product|
      #logger.debug("product"+product.sam_server_product)
      if (product.sam_server_product == true)
      @license_products  << product
      elsif (product.conversion_product_map)
     @license_products << product
      else 
      @service_products << product
      
    end
    end
    
    
    
		# get all the license information for the main page
		@total_license_counts = Entitlement.index_by_status(@sam_customer, true, "Total")
		@pending_license_counts = Entitlement.index_by_status(@sam_customer, true, "Pending")
		@active_license_counts = Entitlement.index_by_status(@sam_customer, true, "Active")
		@grace_period_license_counts = Entitlement.index_by_status(@sam_customer, true, "Grace Period")
		@expired_license_counts = Entitlement.index_by_status(@sam_customer, true, "Expired")
		# get all the service information for the main page
		@total_service_counts = Entitlement.index_by_status(@sam_customer, false, "Total")
		@pending_service_counts = Entitlement.index_by_status(@sam_customer, false, "Pending")
		@active_service_counts = Entitlement.index_by_status(@sam_customer, false, "Active")
		@grace_period_service_counts = Entitlement.index_by_status(@sam_customer, false, "Grace Period")
		@expired_service_counts = Entitlement.index_by_status(@sam_customer, false, "Expired")
		# get all the total information for the main page
		@total_counts = Entitlement.index_by_status(@sam_customer, nil, "Total")
		@pending_counts = Entitlement.index_by_status(@sam_customer, nil, "Pending")
		@active_counts = Entitlement.index_by_status(@sam_customer, nil, "Active")
		@grace_period_counts = Entitlement.index_by_status(@sam_customer, nil, "Grace Period")
		@expired_counts = Entitlement.index_by_status(@sam_customer, nil, "Expired")
		# form the hash of counts
		@entitlement_counts = {}
		@total_license_counts.each {|tlc| @entitlement_counts[tlc.id.to_s + "_0"] = tlc}
		@pending_license_counts.each {|plc| @entitlement_counts[plc.id.to_s + "_1"] = plc}
		@active_license_counts.each {|alc| @entitlement_counts[alc.id.to_s + "_2"] = alc}
		@grace_period_license_counts.each {|gplc| @entitlement_counts[gplc.id.to_s + "_3"] = gplc}
		@expired_license_counts.each {|elc| @entitlement_counts[elc.id.to_s + "_4"] = elc}
		@total_service_counts.each {|tsc| @entitlement_counts[tsc.id.to_s + "_0"] = tsc}
		@pending_service_counts.each {|psc| @entitlement_counts[psc.id.to_s + "_1"] = psc}
		@active_service_counts.each {|asc| @entitlement_counts[asc.id.to_s + "_2"] = asc}
		@grace_period_service_counts.each {|gpsc| @entitlement_counts[gpsc.id.to_s + "_3"] = gpsc}
		@expired_service_counts.each {|esc| @entitlement_counts[esc.id.to_s + "_4"] = esc}
		@total_counts.each {|tsc| @entitlement_counts["all_0"] = tsc}
		@pending_counts.each {|psc| @entitlement_counts["all_1"] = psc}
		@active_counts.each {|asc| @entitlement_counts["all_2"] = asc}
		@grace_period_counts.each {|gpsc| @entitlement_counts["all_3"] = gpsc}
		@expired_counts.each {|esc| @entitlement_counts["all_4"] = esc}
		logger.info("entitlement_counts: #{@entitlement_counts.to_yaml}")
		@table_support = true
		@scrolling_support = true
    @widget_list << Widget.new("entitlement_event_history", "Entitlement Event History", nil, 600, 700)    
    @widget_list << Widget.new("entitlement_details_widget", "Entitlement Information", nil, 500, 700)
		#render(:layout => "entitlement_index_layout")
		#render(:layout => "default")
		#render(:layout => "default_with_docking")
	end
end

def show
  @entitlement = Entitlement.find(params[:id])
  if (!params[:popup].nil?)
    if (!@entitlement.isVirtual?)
  	   render(:partial => "info_popup_window", :locals => {:entitlement => @entitlement})
    else
      virtual_entitlement_audits = VirtualEntitlementAudit.find(:all, :select => "vea.*, ss.name as sam_server_name, ss.id as sam_server_id", 
                :joins => "vea left join sam_server ss on vea.sam_server_id = ss.id
                           left join users u on vea.user_id = u.id", :conditions => ["vea.entitlement_id = ?", @entitlement.id], :order => "time_created desc")
      render(:partial => "info_virtual_popup_window", :locals => {:entitlement => @entitlement, :audits => virtual_entitlement_audits})
    end
  end
end

def new
  gather_data_for_new
  #@entitlement = Entitlement.new
  #@product_list = Product.find(:all, :conditions => "sam_server_product = true", :order => "description").collect {|p| [p.description, p.id]}
end

def create
  #puts "params before strip: #{params.to_yaml}"
  params[:entitlement][:license_count] = params[:entitlement][:license_count].strip
  params[:annotation] = params[:annotation].strip
  if (params[:annotation].empty? or params[:entitlement][:license_count].empty? or params[:entitlement][:license_count].to_i == 0)
    gather_data_for_new
    flash[:notice] = "All fields require a valid value"
    render(:template => "entitlements/new")
    return
  end  
  subcommunity = Product.find(params[:entitlement][:product_id]).subcommunity
  
  begin
    Entitlement.transaction do
      @entitlement = Entitlement.create_virtual_entitlement(@sam_customer, subcommunity, params[:entitlement][:license_count])
      seat_pool = SeatPool.obtain_seat_pool(@sam_customer, subcommunity, nil)
      seat_pool.seat_count += params[:entitlement][:license_count].to_i
      seat_pool.save!
      EntitlementAudit.create(:entitlement => @entitlement, :annotation => params[:annotation], :user => current_user)
      flash[:notice] = "Successfully created virtual entitlement with TMS Entitlement ID #{@entitlement.tms_entitlementid} for #{subcommunity.name}"
      flash[:msg_type] = "info"
    end
  rescue
    flash[:notice] = "Could not create new virtual entitlement at this time" if (flash[:notice].nil?)
  end 
  redirect_to(:action => :index)
end

# deletion of entitlements within SAMC is only available for fake entitlements.
# @see Entitlement#fake?
def delete
  logger.debug "handling request to delete fake entitlement. id: #{params[:id]}"
  
  # defaults, may be overwritten later
  flash[:msg_type] = 'error'
  flash[:notice] = 'Failed to delete fake entitlement.'
  
  entitlement_id = params[:id]
  payload = {
    :id => entitlement_id,
    :method_name => 'delete_fake_entitlement'
  }
  
  logger.info "submitting request to delete entitlement with payload: #{payload.to_yaml}"
  response = CustServServicesHandler.new.dynamic_delete_entitlement(request.env['HTTP_HOST'],
                                               payload,
                                               CustServServicesHandler::ROUTES['entitlement_web_services'] )
  
  logger.info "response.type = #{response.type}, code = #{response.code}"
  logger.debug "response = #{response.to_s}"
  
  if response
    if response.type == 'success' #doesn't mean entitlement was deleted, only that request was handled without exception.
      
      if response.body # must be present and valid JSON. success case example: { "id": 31, "errorMessages": [] }
        begin
          response_data = ActiveSupport::JSON.decode(response.body)
          error_messages = response_data['errorMessages']
          if(error_messages and error_messages.any?)
            flash[:notice] = "Failed to delete fake entitlement: #{error_messages.first}"
          else
            flash[:msg_type] = 'info'
            flash[:notice] = 'Successfully deleted fake entitlement.'
          end
          
        rescue ActiveSupport::JSON::ParseError => parse_error
          logger.error "ERROR: invalid JSON response from Web API call to delete entitlement #{entitlement_id}"
        end
      end
      
    else
      logger.info "ERROR: non-success response for request to delete entitlement #{entitlement_id} : #{response.type} : #{response.body}"
    end
  else logger.error "ERROR: no response from Web API call to delete entitlement #{entitlement_id}"
  end
  
  redirect_to :back
end


def search  
  #put whole array from sam customers search form into session
  #when a request for csv export comes in, :sam_customer will not be included in the request
  if (params[:entitlement])
    session[:entitlement] = params[:entitlement]
  end
  payload = params[:entitlement]
  @entitlements = find_entitlements(payload, FINDER_LIMIT)
  
  @num_rows_reported = @entitlements.length

    if(request.xhr?) #if an ajax request...
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end
    
end

  def find_entitlements(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['entitlement_finder_web_services'] + "#{limit.to_s}")     
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@entitlements = []
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
		parsed_json["entitlements"].each do |e|
			ent = Entitlement.new
			e.each {|k,v|
				ent[k.to_sym] = v
			}
			
			@entitlements << ent
		end
	end	
	@ret_entitlements = @entitlements
  end


def operate_on
  @operation = params[:operation] == "1" ? "Move" : "Deactivate"
  @entitlement_id_list = ""
  params[:moving_entitlements].each do |ms|
    @entitlement_id_list += ms + ","
  end
  @entitlement_id_list.chomp!(",")
  @entitlements = Entitlement.find(:all, :conditions => "id in (#{@entitlement_id_list})")
  @sam_customer = @entitlements[0].sam_customer
  render(:layout => "progress_bar")
end


def history_for
  entitlement_events = EntitlementAudit.find(:all, :select => "distinct ea.*, e.tms_entitlementid, sc1.id as old_sam_customer_id, sc2.id as new_sam_customer_id, sc1.name as old_sam_customer_name, sc2.name as new_sam_customer_name", 
                                          :joins => "ea inner join entitlement e on ea.entitlementid = e.id inner join product p on e.product_id = p.id
                                                      left join sam_customer sc1 on ea.old_sam_customerid = sc1.id left join sam_customer sc2 on ea.new_sam_customerid = sc2.id",
                                          :conditions => ["(old_sam_customerid = ? or new_sam_customerid = ?) and p.id = ?", params[:sam_customer_id], params[:sam_customer_id], params[:product_id]], :order => "ea.created_at desc")
  render(:partial => "entitlement_events", :locals => {:entitlement_events => entitlement_events, :sam_customer_id => params[:sam_customer_id], :product_id => params[:product_id]})
end


# Export entitlement search results to CSV file
def export_entitlements_to_csv
  logger.info "EXPORTING Entitlements CSV, Search params: #{params.to_yaml}"
  # Re-do entitlement search
  entitlements_search_result = Entitlement.search(session[:entitlement])
  # server-side CSV always uses default sort, not necessarily current sort in finder display
  
  csv_string = FasterCSV.generate do |csv_row|
    # header row
    csv_row << ["ID", "TMS Entitlement ID", "Created", "Order Date", PRODUCT_TERM, "License Count", "Subscription Start", "Subscription End", "Order #", "Invoice #", SAM_CUSTOMER_TERM, "State"]
    entitlements_search_result.each do |entitlement|
      # data row
      csv_row << [entitlement.id, entitlement.tms_entitlementid, entitlement.created_at.strftime(DATE_FORM), entitlement.ordered.strftime(JUST_DATE_FORM), entitlement.product_description, entitlement.license_count, (entitlement.subscription_start ? entitlement.subscription_start.strftime(DATE_FORM) : nil), (entitlement.subscription_end ? entitlement.subscription_end.strftime(DATE_FORM) : nil), entitlement.order_num, entitlement.invoice_num, entitlement["sam_customer_name"], entitlement["state_name"]]
    end
  end
  
  send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => ENTITLEMENT_FINDER_RESULTS_FILENAME)
end


# Exports total entitlements to CSV file
def export_all_entitlements_to_csv
  @sam_customer = SamCustomer.find(params[:sam_customer_id])
  @total_counts = get_entitlement_total_counts(@sam_customer)
  
  # Sorts the collection by its description (product description)
  if(@total_counts != nil)
    @total_counts.sort! {|a, b| a.description <=> b.description}
  end

  @pending_counts = get_entitlement_pending_counts
  @active_counts = get_entitlement_active_counts
  @expired_counts = get_entitlement_expired_counts
  
  csv_string = FasterCSV.generate do |csv_row|
    # header row
    csv_row << ["Program", "Total Entitlements", "Pending Entitlements", "Active Entitlements", "Expired Entitlements"]
    @total_counts.each do |total_entitlement|
      pending_count = 0
      active_count = 0
      expired_count = 0
      @pending_counts.each do |pending|
        if(total_entitlement.description == pending.description)
          pending_count = pending.result_count
        end
      end
      @active_counts.each do |active|
        if(total_entitlement.description == active.description)
          active_count = active.result_count
        end
      end
      @expired_counts.each do |expired|
        if(total_entitlement.description == expired.description)
          expired_count = expired.result_count
        end
      end
      # data row
      csv_row << [total_entitlement.description, total_entitlement.result_count, pending_count, active_count, expired_count]
    end
  end
  file_name = "total_entitlements.csv"
  send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
end

def get_entitlement_total_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, nil, "Total")
end

def get_entitlement_pending_counts
  return Entitlement.index_by_status(@sam_customer, nil, "Pending")
end

def get_entitlement_active_counts
  return Entitlement.index_by_status(@sam_customer, nil, "Active")
end

def get_entitlement_expired_counts
  return Entitlement.index_by_status(@sam_customer, nil, "Expired")
end

# Exports service entitlements to CSV file
def export_service_entitlements_to_csv
  @sam_customer = SamCustomer.find(params[:sam_customer_id])
  @total_service_counts = get_entitlement_total_service_counts(@sam_customer)
  
  # Sorts the collection by its description (product description)
  if(@total_service_counts != nil)
    @total_service_counts.sort! {|a, b| a.description <=> b.description}
  end
  
  @pending_service_counts = get_entitlement_pending_service_counts(@sam_customer)
  @active_service_counts = get_entitlement_active_service_counts(@sam_customer)
  @expired_service_counts = get_entitlement_expired_service_counts(@sam_customer)
  
  csv_string = FasterCSV.generate do |csv_row|
    # header row
    csv_row << ["Program", "Total Plans", "Pending Plans", "Active Plans", "Expired Plans"]
    @total_service_counts.each do |service_entitlement|
      pending_count = 0
      active_count = 0
      expired_count = 0
      @pending_service_counts.each do |pending|
        if(service_entitlement.description == pending.description)
          pending_count = pending.result_count
        end
      end
      @active_service_counts.each do |active|
        if(service_entitlement.description == active.description)
          active_count = active.result_count
        end
      end
      @expired_service_counts.each do |expired|
        if(service_entitlement.description == expired.description)
          expired_count = expired.result_count
        end
      end
      # data row
      csv_row << [service_entitlement.description, service_entitlement.result_count, pending_count, active_count, expired_count]
    end
  end
  file_name = "service_entitlements.csv"
  send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
end

def get_entitlement_total_service_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, false, "Total")
end

def get_entitlement_pending_service_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, false, "Pending")
end

def get_entitlement_active_service_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, false, "Active")
end

def get_entitlement_expired_service_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, false, "Expired")
end

# Exports license entitlements to CSV file
def export_license_entitlements_to_csv
  @sam_customer = SamCustomer.find(params[:sam_customer_id])
  @total_license_counts = get_entitlement_total_license_counts(@sam_customer)
  
  if(@total_license_counts != nil)
    # Sorts the collection by its description (product description)
    @total_license_counts.sort! {|a, b| a.description <=> b.description}
  end
  
  @pending_license_counts = get_entitlement_pending_license_counts(@sam_customer)
  @active_license_counts = get_entitlement_active_license_counts(@sam_customer)
  @expired_license_counts = get_entitlement_expired_license_counts(@sam_customer)
  
  @total_license_counts.each do |count|
    logger.info "Testing order: #{count.description}"
  end
  
  csv_string = FasterCSV.generate do |csv_row|
    # header row
    csv_row << ["Program", "Total Entitlements", "Pending Entitlements", "Active Entitlements", "Expired Entitlements"]
    @total_license_counts.each do |license_entitlement|
      pending_count = 0
      active_count = 0
      expired_count = 0
      @pending_license_counts.each do |pending|
        if(license_entitlement.description == pending.description)
          pending_count = pending.result_count
        end
      end
      @active_license_counts.each do |active|
        if(license_entitlement.description == active.description)
          active_count = active.result_count
        end
      end
      @expired_license_counts.each do |expired|
        if(license_entitlement.description == expired.description)
          expired_count = expired.result_count
        end
      end
      # data row
      csv_row << [license_entitlement.description, license_entitlement.result_count, pending_count, active_count, expired_count]
    end
  end
  file_name = "license_entitlements.csv"
  send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
end

def get_entitlement_total_license_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, true, "Total")
end

def get_entitlement_pending_license_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, true, "Pending")
end

def get_entitlement_active_license_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, true, "Active")
end

def get_entitlement_expired_license_counts(sam_customer)
  return Entitlement.index_by_status(sam_customer, true, "Expired")
end


def export_customer_entitlements_to_csv
  selection = params[:selection] || "all" #used to determine if user wants CSV for license entitlements, service entitlements, or all
  logger.info "Exporting Entitlement Details CSV for selection(license, service, all) = " + selection
  
  if (selection == 'license')
    selection = true
  elsif (selection == 'service')
    selection = false
  else
    selection = nil
  end
    
  # Re-do entitlement search
  #not using get_entitlements() because of different param handling. note that CSV generation from Finder uses get_entitlements()
  @entitlements_search_result = Entitlement.search_for_csv(@sam_customer.id.to_s, selection) #note that CSV is always sorted by ascending ID, not necessarily current sort order
  csv_string = FasterCSV.generate do |csv_row|
    # generic header row for all entitlements.  Any field might be applicable to either a license or a service entitlement
    csv_row << ["Entitlement ID", "Created At", "Order #", "Program Group", "Program", "Number of Licenses", "Subscription Start Date", "Subscription End Date", "Bill-To Organization", "Ship-To Organization", "Install-To Organization", "Bill-To UCN", "Ship-To UCN", "Install-To UCN", "Grace Period End Date", "Grace Period Type"]
    @entitlements_search_result.each do |entitlement|
      #if((selection == "all") || (selection == "license" && Boolean(Integer(entitlement.isSamServerProduct))) || (selection == "service" && !Boolean(Integer(entitlement.isSamServerProduct)))) #if the user requested all entitlements, OR this entitlement record matches the type the user requested (isSamServerProduct indicates license type) 
        # data row
        csv_row << [entitlement.id, (entitlement.created_at? ? entitlement.created_at.strftime('%I:%M:%S %p %m/%d/%y') : nil), entitlement.order_num, entitlement.product_group_description, entitlement.product_description, entitlement.license_count, (entitlement.subscription_start? ? entitlement.subscription_start.strftime('%I:%M:%S %p %m/%d/%y') : nil), (entitlement.subscription_end? ? entitlement.subscription_end.strftime('%I:%M:%S %p %m/%d/%y') : nil), entitlement.bill_to_org_name, entitlement.ship_to_org_name, entitlement.install_to_org_name, entitlement.bill_to_ucn, entitlement.ship_to_ucn, entitlement.install_to_ucn, entitlement.grace_period_end_date, entitlement.grace_period_description]

    end
  end
  file_name = "entitlements_search.csv"
  send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
end


def Boolean(integer) #ruby doesn't coerce integer to boolean on its own
   integer!=0
end

#################
# AJAX ROUTINES #
#################

def look_up_new_sam_customer
    @new_sam_customer = SamCustomer.find(params[:new_sam_customer_id])
    @new_org = Org.find_summary_details(@new_sam_customer.root_org.id)
    @entitlement_id_list = params[:entitlement_ids]
    #render(:partial => "new_sam_customer", :locals => {:target_sam_customer => @new_sam_customer, :new_org => @new_org}, :layout => false)
  end

def update_table
  @entitlements = Entitlement.paginate(:page => params[:page],
         :select => "entitlement.*",
         :joins => "inner join sc_entitlement_type on entitlement.sc_entitlement_type_id = sc_entitlement_type.id inner join product on entitlement.product_id = product.id",
         :conditions =>  ["sam_customer_id = ?", params[:sam_customer_id]], :order => entitlement_sort_by_param(params[:sort]), :per_page => 12)
  render(:partial => "sam_customer_entitlements_info", 
         :locals => {:entitlement_collection => @entitlements,
                     :status_indicator => params[:status_indicator],
                     :update_element => params[:update_element],
                     :sam_customer_id => params[:sam_customer_id]})
end


def move  
    @failure = false
    @process_token = nil
    @process = nil
    @process_threads = nil
    @error_descriptions = []
    entitlement_ids = params[:entitlement_ids].split(',').collect{|s| s.strip}.collect{|t| t.to_i}
    puts "entitlement_ids: #{entitlement_ids.to_yaml}"
    my_package = ResourceTransferPackage.new
    first_entitlement = Entitlement.find(entitlement_ids[0])
    my_package.setOldSamCustomerId(first_entitlement.sam_customer.id)
    my_package.setNewSamCustomerId(params[:new_sam_customer_id].to_i)
    resourceSet = HashSet.new
    entitlement_ids.each do |s|
      resourceSet.add(Integer.new(s))
    end
    my_package.setResourceIds(resourceSet)
    puts "The package is: #{my_package.toString()}"
    entitlement_mover = SC.getBean("entitlementMover")
    process_handle = entitlement_mover.run(my_package, Integer.new(current_user.id))
    status_codes = process_handle.getValidationFailures()
    status_codes.each do |status_code|
      logger.info("status code: #{status_code}")
      @error_descriptions << status_code.getDescription()
    end
    @failure = true if @error_descriptions.length > 0
    if (!@failure)
      @process_token = process_handle.getProcessToken()
      logger.info("the process token is: #{@process_token}")
      @process = SamcProcess.find_by_process_token(@process_token)
      logger.info("the process id is: #{@process.id}")
      @process_threads = ProcessMessageResponse.find_incomplete_by_group(@process.id)
      logger.info("the process threads are: #{@process_threads.to_yaml}")
    end
  rescue Exception => e
    logger.info("ERROR: #{e.to_s}")
    @failure = true
  end


def order_set_for
  entitlement = Entitlement.find(params[:id])
  @entitlement_list = Entitlement.find_all_entitlements_by_order_invoice_nums(entitlement.order_num, entitlement.invoice_num)
  respond_to do |format|
      format.html
      format.js {render(:partial => "entitlements/entitlement_list")}
    end
end

private

def gather_data_for_new
  @entitlement = Entitlement.new(params[:entitlement])
  @annotation = params[:annotation]
  @product_list = Product.find(:all, :conditions => "sam_server_product = true", :order => "description").collect {|p| [p.description, p.id]}
end


def entitlement_sort_by_param(sort_by_arg) #used for details table on customer entitlment page, has different fields than Finder
  case sort_by_arg
     when "entitlement_id" then "entitlement.id"
     when "order_date" then "entitlement.ordered"
     when "tms_entitlement_id" then "entitlement.tms_entitlementid"
     when "product_description" then "product.description"
     when "num_licenses" then "entitlement.license_count"
     when "order_number" then "entitlement.order_num"
     when "invoice_number" then "entitlement.invoice_num"
     when "entitlement_type" then "sc_entitlement_type.description, entitlement.created_at desc"
     when "created_at" then "entitlement.created_at"
     
     when "entitlement_id_reverse" then "entitlement.id desc"
     when "order_date_reverse" then "entitlement.ordered desc"
     when "tms_entitlement_id_reverse" then "entitlement.tms_entitlementid desc"
     when "product_description_reverse" then "product.description desc"
     when "num_licenses_reverse" then "entitlement.license_count desc"
     when "order_number_reverse" then "entitlement.order_num desc"
     when "invoice_number_reverse" then "entitlement.invoice_num desc"
     when "entitlement_type_reverse" then "sc_entitlement_type.description desc, entitlement.created_at desc"
     when "created_at_reverse" then "entitlement.created_at desc"
     else "entitlement.created_at desc"
     end
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

  def set_breadcrumb
    @site_area_code = ENTITLEMENTS_CODE
  end

end

class EntitlementLicenseCounts
	attr_accessor :pending_count, :active_count, :expired_count
	def initialize(pending_count, active_count, expired_count)
		@pending_count = pending_count
		@active_count = active_count
		@expired_count = expired_count
	end
end