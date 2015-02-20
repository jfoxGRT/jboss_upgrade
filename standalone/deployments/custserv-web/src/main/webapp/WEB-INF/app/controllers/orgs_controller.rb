require 'fastercsv'

class OrgsController < ApplicationController

	# TODO: Get rid of puts statements
  
  #layout 'new_layout_with_jeff_stuff'
  layout 'default'
  
  def show
      ucn = Org.find(params[:id]).customer.ucn
      @customer_details = Customer.find_details_by_ucn(ucn)
  end
  
  
  def search
    #put whole array from search form into session
    #when generating csv, :org will not be included in the request
    if (!params.nil? && params[:org])
      session[:org] = params[:org]
    end

    payload = params[:org]
    payload.each {|k,v|
      payload[k] = v.to_s.escape_mysql
    }
    
    @orgs = find_orgs(payload, FINDER_LIMIT)
    
    @num_rows_reported = @orgs.length

    if(request.xhr?) #if an ajax request...
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end
  end
  
  def find_orgs(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['org_finder_web_services'] + "#{limit.to_s}")
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@orgs = []
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
		parsed_json["orgs"].each do |e|
			o = Org.new
			e.each {|k,v|
				o[k.to_sym] = v
			}
			
			@orgs << o
		end
	end
	@ret_orgs = @orgs
  end
  
  
  def export_orgs_to_csv
    logger.info "EXPORTING CSV, Params: #{params.to_yaml}"
    # Re-do org search
    orgs_search_result = @orgs = Org.search(session[:org])
	  
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["UCN", "Organization Name", "City", "State", "Postal Code", "Status", "Group", "Type", "SAM EE Customer", "Number of Children"]
      orgs_search_result.each do |org|
        if(!org["sam_customer_id"].nil?)
          is_sam_customer = "Yes"
        else
          is_sam_customer = "No"
        end
        # data row
        csv_row << [org.ucn, org.org_name, org.city_name, org.state_name, org.postal_code, org.status_description, org.group_description, org.type_description, is_sam_customer, org.number_of_children]
      end
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => ORG_FINDER_RESULTS_FILENAME)
  end
  
  #################
  # AJAX ROUTINES #
  #################
  
  
  def dialog_popup
	@org = Customer.find_details_by_ucn(params[:ucn])
	if (@org)
		@sam_customer = @org.sam_customer_id ? SamCustomer.find(@org.sam_customer_id) : nil
		@number_billed_to = Entitlement.count(:conditions => ["bill_to_org_id = ?", @org.id])
		@number_shipped_to = Entitlement.count(:conditions => ["ship_to_org_id = ?", @org.id])
		@number_installed_to = Entitlement.count(:conditions => ["install_to_org_id = ?", @org.id])
		render(:partial => "org_widget", :object => @org, 
				:locals => {:sam_customer => @sam_customer, 
				:number_billed_to => @number_billed_to, 
				:number_shipped_to => @number_shipped_to, 
				:number_installed_to => @number_installed_to})
	else
		render(:text => "ERROR")
	end
  end
  
  
  def dialog_show_org_details
	@org = Customer.find_details_by_ucn(params[:ucn])
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
  
  
  #def dialog_show_children
	#	@org = Org.find(params[:org_id])
	#render(:text => "#{@org.id}")
  #end
  
  def dialog_get_children
	@customer = Customer.find_by_ucn(params[:ucn])
	@parent_customer = Customer.find_parent_by_customer_id(@customer.id)
    @descendant_orgs = Customer.find_descendants_minimum_field_set(params[:ucn])
	render(:partial => "org_widget_children", :object => @customer, :locals => {:descendant_orgs => @descendant_orgs, :parent_customer => @parent_customer})
  end
  
   def dialog_get_parent
  @customer = Customer.find_by_ucn(params[:ucn])
  @parent_customer = Customer.find_parent_by_customer_id(@customer.id)
  if @parent_customer
   @descendant_orgs = Customer.find_descendants_minimum_field_set(@parent_customer.ucn)
   render(:partial => "org_widget_children", :object => @parent_customer, :locals => {:descendant_orgs => @descendant_orgs, :parent_customer => nil})
 else
   @descendant_orgs = Customer.find_descendants_minimum_field_set(params[:ucn])
   render(:partial => "org_widget_children", :object => @customer, :locals => {:descendant_orgs => @descendant_orgs, :parent_customer => @parent_customer})
   end
   
  end
  
  
  
  
  
  
  
  def find_ucn
    if (!params[:id].nil?)
      ucn = params[:id]
    else
      ucn = params[:org_name]
    end
    @customer_details = Customer.find_details_by_ucn(ucn)
  end
  
  def show_hierarchy
    @customer_under_lens = Customer.find_by_ucn(params[:id])
    @descendant_orgs = Customer.find_descendants_minimum_field_set(params[:id])
  end
  
  def go_to_ancestor
    @customer_under_lens = Customer.find_parent_by_customer_id(params[:id])
    @descendant_orgs = Customer.find_descendants_minimum_field_set(@customer_under_lens.ucn)
  end
  
  
  def change_selected
    puts "params: #{params.to_yaml}"
    get_detailed_info_for_ucn(params[:ucn])
    respond_to do |format|
      format.html
      format.js {render(:partial => "orgs/org_detailed_info")}
    end
  end
  
  def search_summary_info_for
    ucn_list = get_ucn_list_from_query_string
    puts "ucn_list: #{ucn_list.to_yaml}"
    @drop_down_list = []
    if (!params[:ucn1].nil?)
      get_detailed_info_for_ucn(params[:ucn1])
      @number = 1
    elsif (!params[:user_ucn].nil?)
      get_detailed_info_for_ucn(params[:user_ucn])
      @number = 0
    end  
    ucn_list.each do |ucn|
      @drop_down_list << Customer.find(:first, :select => "c.ucn, trim(o.name) as name", :joins => "c inner join org o on o.customer_id = c.id",
                                        :conditions => ["c.ucn = ?", ucn])
    end
    
    puts "@org: #{@org.to_yaml}"
    puts "@drop_down_list: #{@drop_down_list.to_yaml}"
    respond_to do |format|
      format.html
      format.js {render(:partial => "orgs/search_popup_window")}
    end
  end
  
  def add_to_task
    puts "params: #{params.to_yaml}"
    customer = Customer.find(:first, :select => "c.*, org.id as org_id", :joins => "c inner join org on org.customer_id = c.id", :conditions => ["c.ucn = ?", params[:ucn]])
    TaskOrg.create(:task_id => params[:id], :org_id => customer.org_id, :user_id => current_user.id)
    respond_to do |format|
      format.html
      format.js {render(:text => "hey jeff", :layout => nil)}
    end
  end
  
  def show_summary_info_for
    #puts "params: #{params.to_yaml}"
    get_detailed_info_for_ucn(params[:id])
    respond_to do |format|
      format.html {render(:partial => "info_popup_window")}
      format.js {render(:partial => "info_popup_window")}
    end
  end
  
  
  private
    
  def get_detailed_info_for_ucn(p_ucn)
    @org = Customer.find_details_by_ucn(p_ucn)
    bill_to_type = EntitlementOrgType.find_by_code(EntitlementOrgType.BILL_TO_CODE)
    ship_to_type = EntitlementOrgType.find_by_code(EntitlementOrgType.SHIP_TO_CODE)
    sam_customer_id = @org.sam_customer_id
    @number_assigned_to = (sam_customer_id.nil?) ? 0 : Entitlement.count(:conditions => ["sam_customer_id = ?", sam_customer_id])
    @number_billed_to = EntitlementOrg.count(:conditions => ["entitlement_org_type_id = ? and org_id = ?", bill_to_type.id, @org.id])
    @number_shipped_to = EntitlementOrg.count(:conditions => ["entitlement_org_type_id = ? and org_id = ?", ship_to_type.id, @org.id])
    tech_support_group = ProductGroup.find_by_code(ProductGroup.TECH_SUPPORT)
    @support_plan = (Entitlement.find(:all, :select => "e.*", :joins => "e inner join entitlement_org eo on eo.entitlement_id = e.id inner join product p on e.product_id = p.id", 
                                     :conditions => ["p.product_group_id = ? and eo.org_id = ?", tech_support_group.id, @org.id]).length > 0)
  end
  
  def get_ucn_list_from_query_string
    ucns = []
    request.query_string.split("&").each do |q|
      tmp = q.split("ucn=")
      puts "tmp: #{tmp.to_yaml}"
      ucns << tmp[1] if (!tmp[1].nil?)
    end
    return ucns.uniq
  end
  
end
