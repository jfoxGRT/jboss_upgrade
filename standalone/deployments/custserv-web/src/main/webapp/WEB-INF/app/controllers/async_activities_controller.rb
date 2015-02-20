class AsyncActivitiesController < AgentConversationsController
  
  def show
    @conversation   = ConversationInstance.find(params[:convo_id])
    @async_activity = @conversation.async_activity
    @agent          = @conversation.agent
    @sam_server     = @agent.sam_server
    @sam_customer   = @sam_server.sam_customer
  end
  
  def async_file_upload_error_stacktrace
    @async_file_upload = AsyncFileUpload.find(params[:async_file_upload_id])
    
    if (@async_file_upload.file_extension == 'xml')
      full_xml = @async_file_upload.error_stacktrace
      
      exception_cause_xml = full_xml.split(/<exception><cause>/)
      exception_cause_xml = exception_cause_xml[1].split(/<\/cause><stack_trace>/)[0]
      exception_cause_xml = exception_cause_xml.split(/CDATA\[/)[1]
      exception_cause_xml = exception_cause_xml.split(/]]>/)[0]
      logger.debug "JF: exception_cause_xml = " + exception_cause_xml.to_s
      
      stack_trace_xml = full_xml.split(/<stack_trace>/)[1]
      stack_trace_xml = stack_trace_xml.split(/CDATA\[/)[1]
      stack_trace_xml = stack_trace_xml.split(/=>]]>/)[0]
      stack_trace_xml = stack_trace_xml.gsub(/=>/, "=>\n")
      logger.debug "JF: stack_trace_xml = " + stack_trace_xml
  
      additional_info_xml = full_xml.split(/<additional_info>/)[1]
      additional_info_xml = additional_info_xml.split(/CDATA\[/)[1]
      additional_info_xml = additional_info_xml.split(/]]>/)[0]
      additional_info_xml = additional_info_xml.gsub(/\s=>\s/, " =>\n")
      
      @exception_cause = exception_cause_xml
      @stack_trace = stack_trace_xml
      @additional_info = additional_info_xml
    elsif (@async_file_upload.file_extension == 'csv')
      @exception_cause = @async_file_upload.error_stacktrace
    end
  end 
  
end
