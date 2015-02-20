class ConversationAlertsController < AgentConversationsController
  
  layout "default"
  
  def index
    @alert_instances = AlertInstance.find(:all, :select => "ai.*, a.description", :joins => "ai inner join alert a on ai.alert_id = a.id", :conditions => ["conversation_instance_id = ?", @conversation.id])
  end
  
end
