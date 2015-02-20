class SamCustomerAlertInstancesController < SamCustomerAlertsController
  
  #layout "new_layout_with_jeff_stuff"
  layout "default"
  
  def index
    #puts "params: #{params.to_yaml}"
    if ((@alert.code == Alert.AGENT_EVENT_PROBLEM_CODE) || (@alert.code == Alert.AGENT_EVENT_INFO_CODE))
      @agent_event_alert_groups = AlertInstance.find(:all, :select => "ag.id as agent_id, ss.id as server_id, ss.name as server_name, count(*) as alert_count", 
                                                     :joins => "ai inner join alert a on ai.alert_id = a.id inner join agent ag on ai.agent_id = ag.id 
                                                                left join sam_server ss on ag.sam_server_id = ss.id",
                                                     :conditions => ["ai.sam_customer_id = ? and ai.alert_id = ?", @sam_customer.id, @alert.id], :group => "ag.id", :order => "server_name")
      render(:template => "sam_customer_alert_instances/agent_alert_list")
    else
      @alert_instances = AlertInstance.find(:all, :conditions => ["sam_customer_id = ? and alert_id = ?", @sam_customer.id, @alert.id], :order => "created_at desc")
      render(:template => "sam_customer_alert_instances/non_agent_alert_list")
    end
  end
  
end
