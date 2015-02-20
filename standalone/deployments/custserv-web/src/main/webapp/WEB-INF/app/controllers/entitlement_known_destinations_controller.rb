class EntitlementKnownDestinationsController < SamCustomersController
  
  def index
    known_entitlement_destinations = EntitlementKnownDestination.find_by_sql(["select distinct(ekd.id), ekd.org1_id, ekd.org2_id, ekd.entitlement_id, \
                                            ekd.sam_customer_id from entitlement_known_destinations ekd, org where (ekd.org1_id = org.id or ekd.org2_id = org.id) and \
                                            (ekd.sam_customer_id = ?) order by org.name;", @sam_customer.id])
    @known_entitlement_destinations = known_entitlement_destinations.paginate(:page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
  end
  
  def new
    @mode = "Add"
    @entitlement_known_destination = EntitlementKnownDestination.new
    render(:template => "entitlement_known_destinations/form")
  end
  
  def create
    @mode = "Add"
    @entitlement_known_destination = EntitlementKnownDestination.new(params[:entitlement_known_destination])
    if(EntitlementKnownDestination.find_by_orgs(@entitlement_known_destination.bill_to_org, @entitlement_known_destination.ship_to_org))
      flash[:notice] = "That destination has already been created for #{@entitlement_known_destination.sam_customer.name}"
      render(:template => "entitlement_known_destinations/form")
      return
    end
    (render(:template => "entitlement_known_destinations/form") and return) if (!@entitlement_known_destination.valid?)
    @entitlement_known_destination.save
    flash[:notice] = "Destination created successfully"
    flash[:msg_type] = "info"
    redirect_to(:action => :index)
  end
  
  def edit
    @mode = "Edit"
    @entitlement_known_destination = EntitlementKnownDestination.find(params[:id])
    render(:template => "entitlement_known_destinations/form")
  end
  
  def update
    @mode = "Edit"
    @entitlement_known_destination = EntitlementKnownDestination.new(params[:entitlement_known_destination])
    @entitlement_known_destination.id = params[:id]
    if((ekd = EntitlementKnownDestination.find_by_orgs(@entitlement_known_destination.bill_to_org, @entitlement_known_destination.ship_to_org)) && (ekd.id != @entitlement_known_destination.id))
      flash[:notice] = "That destination has already been created for #{ekd.sam_customer.name}"
      render(:template => "entitlement_known_destinations/form")
      return
    end
    (render(:template => "entitlement_known_destinations/form") and return) if (!@entitlement_known_destination.valid?)
    EntitlementKnownDestination.update(params[:id], params[:entitlement_known_destination])
    flash[:notice] = "Destination updated successfully"
    flash[:msg_type] = "info"
    redirect_to(:action => :index)
  end
  
  def destroy
    @killed_destination_id = params[:id]
    EntitlementKnownDestination.delete(params[:id])
  end
  
  #################
  # AJAX ROUTINES #
  #################
  
  def update_known_entitlement_destinations_table
    known_entitlement_destinations = EntitlementKnownDestination.find_by_sql(["select distinct(ekd.id), ekd.org1_id, ekd.org2_id, ekd.entitlement_id, \
                                            ekd.sam_customer_id from entitlement_known_destinations ekd, org where (ekd.org1_id = org.id or ekd.org2_id = org.id) and \
                                            (ekd.sam_customer_id = ?) order by org.name;", @sam_customer.id])
    if(params[:sort] == "bill_to_org")
      known_entitlement_destinations.sort!{|a,b| a.bill_to_org.name.strip <=> b.bill_to_org.name.strip}
    elsif(params[:sort] == "bill_to_org_reverse")
      known_entitlement_destinations.sort!{|a,b| b.bill_to_org.name.strip <=> a.bill_to_org.name.strip}
    elsif(params[:sort] == "ship_to_org")
      known_entitlement_destinations.sort!{|a,b| a.ship_to_org.name.strip <=> b.ship_to_org.name.strip}
    elsif(params[:sort] == "ship_to_org_reverse")
      known_entitlement_destinations.sort!{|a,b| b.ship_to_org.name.strip <=> a.ship_to_org.name.strip}
    end
    
    @known_entitlement_destinations = known_entitlement_destinations.paginate(:page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "known_entitlement_destinations_info",
           :locals => {:known_entitlement_destination_collection => @known_entitlement_destinations,
                              :status_indicator => "known_entitlement_destinations_loading_indicator",
                              :update_element => "known_entitlement_destinations_table",
                              :sam_customer_id => @sam_customer.id})
  end
  
end
