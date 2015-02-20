class AlertsController < ApplicationController
  
  before_filter :load_alert
  
  layout "default"
  
  protected
  
  def load_alert
    @alert = Alert.find(params[:notification_type_id]) if !params[:notification_type_id].nil?
  end
  
end
