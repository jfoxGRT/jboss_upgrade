class AuditsController < SamCustomersController
  
  before_filter :set_breadcrumb
  
  layout 'default'
  
  def index
    (redirect_to(:action => :index, :controller => :home) and return) if @sam_customer.nil?
    @licensing_activations = LicensingActivation.find(:all, :conditions => ["sam_customer_id = ?", @sam_customer.id])
    @tasks = Task.find_task_summaries_for_sam_customer(@sam_customer.id)
  end  
  
  def show
    @licensing_activation = LicensingActivation.find(params[:id])
    @entitlement_audits = EntitlementAudit.find_all_by_licensing_activation_id(params[:id])
  end
  
  def sam_customers
    @sam_customers = SamCustomer.find(:all)
  end
  
  def license_reallocations
    @sam_customer = SamCustomer.find(params[:id])
    @seat_activities = SeatActivity.find(:all, :select => "seat_activity.*", 
                                         :joins => "inner join seat_pool on seat_activity.seat_pool_id = seat_pool.id",
                                         :conditions => ["seat_pool.sam_customer_id = ? and seat_activity.done = true", params[:id]])
  end
  
  def virtual_entitlements
    @licensing_activation = LicensingActivation.find(params[:id])
    @entitlement_audits = EntitlementAudit.find_all_by_licensing_activation_id(params[:id])
  end
  
  private
  
  def set_breadcrumb
    @site_area_code = CS_REP_ACTIVITY_CODE
  end
  
end