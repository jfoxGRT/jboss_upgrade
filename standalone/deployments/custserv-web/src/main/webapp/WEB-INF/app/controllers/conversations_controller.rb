class ConversationsController < ApplicationController
  
  before_filter :load_conversation
  
  def show
    @conversation = ConversationInstance.find(params[:id])
  end
  
  protected
  
  def load_conversation
    @conversation = ConversationInstance.find(params[:conversation_instance_id]) if !params[:conversation_instance_id].nil?
  end
  
end
