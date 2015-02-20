class AlertInstancesController < AlertsController
  
  #layout "new_layout_with_jeff_stuff"
  layout "default"
  
  def index
    puts "params: #{params.to_yaml}"
    @alert_instances = AlertInstance.find_recent_by_alert_id(current_user, @alert.id)
  end
  
  def group_by_sam_customer
    if(@alert.code == "AGENT_EVENT_PROBLEM")
      @alert_instances = AlertInstance.group_recent_aep_by_sam_customer
    else
      @alert_instances = AlertInstance.group_recent_by_sam_customer(@alert.id)
    end
  end
  
  def group_by_server
    @alert = Alert.find(params[:alert_id])
    conditions_clause_str = "ai.alert_id = ? and ap.name = 'eventType'"
    conditions_clause_fillins = [@alert.id]
    if (params[:sam_server_id])
      @sam_server = SamServer.find(params[:sam_server_id])
      @sam_customer = @sam_server.sam_customer
      conditions_clause_str += " and ai.server_id = ?"
      conditions_clause_fillins << params[:sam_server_id]
    end
    @alert_instance_group_list = AlertInstance.find(:all, :select => "ap.value, count(*) as the_count", 
                       :joins => "ai inner join alert a on ai.alert_id = a.id 
                                  inner join alert_params ap on ap.alert_instance_id = ai.id",
                       :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :group => "ap.value")
    puts "alert_instance_group_list size: #{@alert_instance_group_list.length}"
    if (@sam_server)
      render(:template => "alert_instances/group_alert_instances_by_sam_customer_sam_server")
    else
      render(:template => "alert_instances/group_alert_instances_by_sam_server")
    end
  end
  
  def group_by_event_type
    @alert = Alert.find(params[:alert_id])
    conditions_clause_str = "ai.alert_id = ? and ap.name = 'eventType' and ap.value = ?"
    conditions_clause_fillins = [@alert.id, params[:event_type]]
    @event_type = params[:event_type]
    if (params[:sam_server_id])
      @sam_server = SamServer.find(params[:sam_server_id])
      @sam_customer = @sam_server.sam_customer
      conditions_clause_str += " and ai.server_id = ?"
      conditions_clause_fillins << params[:sam_server_id]
    end
    @alert_instances = AlertInstance.find(:all, :select => "ai.*",
                       :joins => "ai inner join alert a on ai.alert_id = a.id 
                                  inner join alert_params ap on ap.alert_instance_id = ai.id",
                       :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :order => "ai.created_at desc")
    if (@sam_server)
      render(:template => "alert_instances/group_alert_instances_by_sam_server_event_type")
    else
      render(:template => "alert_instances/group_alert_instances_by_event_type")
    end
  end
  
end
