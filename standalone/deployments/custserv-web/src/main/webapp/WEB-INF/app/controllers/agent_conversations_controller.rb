class AgentConversationsController < AgentsController
  
  before_filter :load_conversation, :initialize_view_vars
  
  layout 'default'
  
  def index
    @conversations = ConversationInstance.paginate(:page => params[:page], :select => "conversation_instance.*, conversation_result_type.name",
                                                   :joins => "inner join conversation_result_type on conversation_instance.result_type_id = conversation_result_type.id
                                                              inner join agent on conversation_instance.agent_id = agent.id
                                                              inner join sam_server on agent.sam_server_id = sam_server.id", 
                                                   :conditions => ["sam_server.sam_customer_id = ? and sam_server.id = ?", @sam_customer.id, @sam_server.id],
                                                   :order => "id desc", :per_page => PAGINATION_ROWS_PER_PAGE)
  end
  
  def show
    @conversation = ConversationInstance.find(params[:id])
  end

  #################
  # AJAX ROUTINES #
  #################

  def update_table
    #puts "params: #{params.to_yaml}"
    conversations = ConversationInstance.paginate(:page => params[:page], :select => "conversation_instance.*, conversation_result_type.name",
                                                   :joins => "inner join conversation_result_type on conversation_instance.result_type_id = conversation_result_type.id \
                                                              inner join agent on conversation_instance.agent_id = agent.id \
                                                              inner join sam_server on agent.sam_server_id = sam_server.id", 
                                                   :conditions => ["sam_server.sam_customer_id = ? and sam_server.id = ?", @sam_customer.id, @sam_server.id],
                                                   :order => conversations_sort_by_param(params[:sort]), :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "conversation_info", 
           :locals => {:conversation_collection => conversations,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :sam_customer => @sam_customer,
                       :sam_server => @sam_server}, :layout => false)
  end
  
  protected
  
  def load_conversation
    @conversation = ConversationInstance.find(params[:conversation_id]) if params[:conversation_id]
  end
  
  private
  
  def conversations_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "conversationid" then "conversation_instance.id"
      when "adapteridentifier" then "conversation_instance.adapter_identifier"
      when "conversationidentifier" then "conversation_instance.conversation_identifier"
      when "started" then "conversation_instance.started"
      when "completed" then "conversation_instance.completed"
      when "resultmsg" then "conversation_result_type.name"
      when "retrytimeoutend" then "conversation_instance.retry_timeout_end"
      when "retryparentconversationid" then "conversation_instance.retry_parent_conversation_instance_id"
      when "retryoriginalconversationid" then "conversation_instance.retry_original_conversation_instance_id"
      when "priority" then "conversation_instance.priority"
      
      when "conversationid_reverse" then "conversation_instance.id desc"
      when "adapteridentifier_reverse" then "conversation_instance.adapter_identifier desc"
      when "conversationidentifier_reverse" then "conversation_instance.conversation_identifier desc"
      when "started_reverse" then "conversation_instance.started desc"
      when "completed_reverse" then "conversation_instance.completed desc"
      when "resultmsg_reverse" then "conversation_result_type.name desc"
      when "retrytimeoutend_reverse" then "conversation_instance.retry_timeout_end desc"
      when "retryparentconversationid_reverse" then "conversation_instance.retry_parent_conversation_instance_id desc"
      when "retryoriginalconversationid_reverse" then "conversation_instance.retry_original_conversation_instance_id desc"
      when "priority_reverse" then "conversation_instance.priority desc"
      else "conversation_instance.completed desc"
    end
  end
  
  def initialize_view_vars
    @site_area_code = SAM_SERVERS_CODE
    @prototype_required = true
  end
  
end
