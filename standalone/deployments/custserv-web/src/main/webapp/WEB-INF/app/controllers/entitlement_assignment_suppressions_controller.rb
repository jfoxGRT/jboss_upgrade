class EntitlementAssignmentSuppressionsController < ApplicationController
  
  layout 'new_layout_with_jeff_stuff'
  
  def index
    @entitlement_assignment_suppressions = EntitlementAssignmentSuppression.paginate(:all, :select => "eas.*, org.name, users.last_name",
                                              :page => params[:page], :joins => "eas inner join org on eas.org_id = org.id \
                                                                                 inner join users on eas.user_id = users.id", 
                                              :order => "org.name", :per_page => PAGINATION_ROWS_PER_PAGE)
  end
  
  def new
    @entitlement_assignment_suppression = EntitlementAssignmentSuppression.new
  end
  
  def create
    @entitlement_assignment_suppression = EntitlementAssignmentSuppression.new(params[:entitlement_assignment_suppression])
    @entitlement_assignment_suppression.user = current_user
    if (EntitlementAssignmentSuppression.find_by_ucn(@entitlement_assignment_suppression.ucn))
      flash[:notice] = "That UCN is already a root organization for entitlement assignment suppression.  Please try again."
      render("entitlement_assignment_suppressions/new")
      return
    end
    (render("entitlement_assignment_suppressions/new") and return) if (!@entitlement_assignment_suppression.valid?)
    @entitlement_assignment_suppression.save
    flash[:notice] = "Successfully added entitlement assignment suppression record"
    flash[:msg_type] = "info"
    redirect_to(:action => :index)
  end
  
  def show
    @entitlement_assignment_suppression = EntitlementAssignmentSuppression.find(params[:id])
  end
  
  def destroy
    @entitlement_assignment_suppression = EntitlementAssignmentSuppression.find(params[:id])
    EntitlementAssignmentSuppression.delete(@entitlement_assignment_suppression.id)
  end
  
  #################
  # AJAX ROUTINES #
  #################
  
  def update_eas_table
    eas = EntitlementAssignmentSuppression.paginate(:all, :select => "eas.*, org.name, users.last_name",
                                              :page => params[:page], :joins => "eas inner join org on eas.org_id = org.id \
                                                                                 inner join users on eas.user_id = users.id", 
                                              :order => eas_sort_by_param(params[:sort]), :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "eas_info", :locals => {:eas_collection => eas,
                                               :status_indicator => params[:status_indicator],
                                               :update_element => params[:update_element]}, :layout => false)
  end
  
  private
  
  def eas_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "created_at" then "eas.created_at"
      when "updated_at" then "eas.updated_at"
      when "organization" then "org.name"
      when "user" then "users.last_name"
            
      when "created_at_reverse" then "eas.created_at desc"
      when "updated_at_reverse" then "eas.updated_at desc"
      when "organization_reverse" then "org.name desc"
      when "user_reverse" then "users.last_name desc"
    end
  end
  
end
