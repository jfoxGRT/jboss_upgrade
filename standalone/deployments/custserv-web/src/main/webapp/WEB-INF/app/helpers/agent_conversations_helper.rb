module AgentConversationsHelper
  
  def translate_conversation_result_code(result_code)
    case result_code
      when 0 then "Unknown"
      when 1 then "Internal Version Compatibility Problem"
      when 2 then "No Schools Qualify"
    end
  end
  
end
