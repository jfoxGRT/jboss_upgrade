class SamCustomerAlertsController < SamCustomersController
  
  #layout 'new_layout_with_jeff_stuff'
  layout "default"
  
  before_filter :load_alert
  
  def index
    if (current_user.isScholasticType)
      conditions_clause = ["ai.sam_customer_id = ? and a.user_type = 's'", @sam_customer.id]
    else
      conditions_clause = ["ai.sam_customer_id = ?", @sam_customer.id]
    end
    @alert_counts = AlertInstance.find(:all, :select => "a.id, a.code, a.description, a.msg_type, count(*) as alert_count", :joins => "ai inner join alert a on ai.alert_id = a.id",
                                       :conditions => conditions_clause, :order => "a.description", :group => "a.code")
  end
  
  protected
  
  def load_alert
    @alert = Alert.find(params[:notification_type_id]) if !params[:notification_type_id].nil?
  end
  
end
