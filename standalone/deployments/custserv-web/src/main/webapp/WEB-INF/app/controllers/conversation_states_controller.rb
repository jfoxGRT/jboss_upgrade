class ConversationStatesController < AgentConversationsController
  
  def show
    @conversation_command = ConversationCommand.find(:first, :conditions => ["conversation_state_instance_id = ?", params[:id]])
    @conversation_state = @conversation_command.conversation_state_instance
    @conversation = @conversation_state.conversation_instance
  end
  
end
