
class SamCentralMessagesController < ApplicationController
  
  before_filter :load_view_vars
  
  layout 'default'
  
  def index
    #@scm_alt_count = SamCentralMessageAlt.count
    #@alt_head = SamCentralMessageAlt.find(:first, :order => "priority desc, id asc")
    #@alt_head_parsed = JSON.pretty_generate(JSON.parse(@alt_head.message)) if !@alt_head.nil?
    
    @scm_auth_count = SamCentralMessageAuth.count
    @auth_head = SamCentralMessageAuth.find(:first, :order => "priority desc, id asc")
    #@auth_head_parsed = JSON.pretty_generate(JSON.parse(@auth_head.message)) if !@auth_head.nil?
    
    @scm_commander_count = SamCentralMessageCommander.count
    @commander_head = SamCentralMessageCommander.find(:first, :order => "priority desc, id asc")
    #@commander_head_parsed = JSON.pretty_generate(JSON.parse(@commander_head.message)) if !@commander_head.nil?
    
    @scm_core_audit_count = SamCentralMessageCoreAudit.count
    @core_audit_head = SamCentralMessageCoreAudit.find(:first, :order => "priority desc, id asc")
    #@core_audit_head_parsed = JSON.pretty_generate(JSON.parse(@core_audit_head.message)) if !@core_audit_head.nil?
    
    @scm_core_email_count = SamCentralMessageCoreEmail.count
    @core_email_head = SamCentralMessageCoreEmail.find(:first, :order => "priority desc, id asc")
    #@core_email_head_parsed = JSON.pretty_generate(JSON.parse(@core_email_head.message)) if !@core_email_head.nil?
    
    @scm_core_processor_count = SamCentralMessageCoreProcessor.count
    @core_processor_head = SamCentralMessageCoreProcessor.find(:first, :order => "priority desc, id asc")
    #@core_processor_head_parsed = JSON.pretty_generate(JSON.parse(@core_processor_head.message)) if !@core_processor_head.nil?
    
    @scm_messaging_count = SamCentralMessageMessaging.count
    @messaging_head = SamCentralMessageMessaging.find(:first, :order => "priority desc, id asc")
    #@messaging_head_parsed = JSON.pretty_generate(JSON.parse(@messaging_head.message)) if !@messaging_head.nil?
    
    @scm_tms_temp_out_count = TmsTempOut.count
    @scm_tms_fake_in_count = TmsFakeIn.count
    @scm_csi_temp_out_count = CsiTempOut.count
    @scm_csi_fake_in_count = CsiFakeIn.count
    
    @unprocessed_emails_count = EmailMessage.count(:conditions => ["sent_date is null and ignored_date is null"])
    oldest_unprocessed_email = EmailMessage.find(:first, :select => "generated_date", :conditions => "sent_date IS null AND ignored_date IS null")
    @unprocessed_email_timestamp = oldest_unprocessed_email.generated_date if oldest_unprocessed_email
  end
  
  
  def edit
    @queue = params[:id]
    case @queue
      #when SamCentralMessageAlt.QUEUE_NAME then @head = SamCentralMessageAlt.find(:first, :order => "id")
      when SamCentralMessageAuth.QUEUE_NAME then @head = SamCentralMessageAuth.find(:first, :order => "id")
      when SamCentralMessageCommander.QUEUE_NAME then @head = SamCentralMessageCommander.find(:first, :order => "id")
      when SamCentralMessageCoreAudit.QUEUE_NAME then @head = SamCentralMessageCoreAudit.find(:first, :order => "id")
      when SamCentralMessageCoreEmail.QUEUE_NAME then @head = SamCentralMessageCoreEmail.find(:first, :order => "id")
      when SamCentralMessageCoreProcessor.QUEUE_NAME then @head = SamCentralMessageCoreProcessor.find(:first, :order => "id")
      when SamCentralMessageMessaging.QUEUE_NAME then @head = SamCentralMessageMessaging.find(:first, :order => "id")
    end
    #@head_parsed = JSON.pretty_generate(JSON.parse(@head.message)) if !@head.nil?
  end
  
  
  def stats
    @queue_name = params[:queue_name]
    logger.debug "looking up stats for #{@queue_name}"
    case @queue_name
      #when SamCentralMessageAlt.QUEUE_NAME then @head = SamCentralMessageAlt.find(:first, :order => "id")
      when SamCentralMessageAuth.QUEUE_NAME then @head = SamCentralMessageAuth.find(:first, :order => "id")
      when SamCentralMessageCommander.QUEUE_NAME then @head = SamCentralMessageCommander.find(:first, :order => "id")
      when SamCentralMessageCoreAudit.QUEUE_NAME then @head = SamCentralMessageCoreAudit.find(:first, :order => "id")
      when SamCentralMessageCoreEmail.QUEUE_NAME then @head = SamCentralMessageCoreEmail.find(:first, :order => "id")
      when SamCentralMessageCoreProcessor.QUEUE_NAME then @head = SamCentralMessageCoreProcessor.find(:first, :order => "id")
      when SamCentralMessageMessaging.QUEUE_NAME then @head = SamCentralMessageMessaging.find(:first, :order => "id")
    end
    
    throughput_records = SamCentralMessageBatchHistory.get_reporting_history_for_queue(@queue_name)
    @average_batch_time = SamCentralMessageBatchHistory.get_average_batch_time_for_queue(@queue_name).to_s
    
    @max = 0 #part of a workaround for bug in graph autoscale
    display_array = Array.new
    throughput_records.each do |throughput_record|
      display_array << [throughput_record[:hour], throughput_record[:avg_messages_per_hour]]
      @max = throughput_record[:avg_messages_per_hour].to_i if throughput_record[:avg_messages_per_hour].to_i > @max
    end
    
    @display_json = display_array.to_json
    render(:partial => "stats")
  end
 
 
  def update
    queue = params[:queue]
    logger.debug "updating message #{params[:id]} from queue #{queue}"
    case queue
      #when SamCentralMessageAlt.QUEUE_NAME then SamCentralMessageAlt.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
      when SamCentralMessageAuth.QUEUE_NAME then @head = SamCentralMessageAuth.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
      when SamCentralMessageCommander.QUEUE_NAME then @head = SamCentralMessageCommander.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
      when SamCentralMessageCoreAudit.QUEUE_NAME then @head = SamCentralMessageCoreAudit.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
      when SamCentralMessageCoreEmail.QUEUE_NAME then @head = SamCentralMessageCoreEmail.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
      when SamCentralMessageCoreProcessor.QUEUE_NAME then @head = SamCentralMessageCoreProcessor.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
      when SamCentralMessageMessaging.QUEUE_NAME then @head = SamCentralMessageMessaging.update_all("message = '#{params[:new_message_text]}'", "id = #{params[:id]}")
    end
    redirect_to(sam_central_messages_path)
  end
  
  
  def destroy
    queue = params[:queue]
    logger.debug "deleting message #{params[:id]} from queue #{queue}"
    case queue
      #when SamCentralMessageAlt.QUEUE_NAME then SamCentralMessageAlt.delete(params[:id])
      when SamCentralMessageAuth.QUEUE_NAME then SamCentralMessageAuth.delete(params[:id])
      when SamCentralMessageCommander.QUEUE_NAME then SamCentralMessageCommander.delete(params[:id])
      when SamCentralMessageCoreAudit.QUEUE_NAME then SamCentralMessageCoreAudit.delete(params[:id])
      when SamCentralMessageCoreEmail.QUEUE_NAME then SamCentralMessageCoreEmail.delete(params[:id])
      when SamCentralMessageCoreProcessor.QUEUE_NAME then SamCentralMessageCoreProcessor.delete(params[:id])
      when SamCentralMessageMessaging.QUEUE_NAME then SamCentralMessageMessaging.delete(params[:id])
    end
    redirect_to(sam_central_messages_path)
  end
 
 
  #################
  # AJAX ROUTINES #
  #################
  
  def update_message_queue_counts
    
    #@scm_alt_count = SamCentralMessageAlt.count
    #@alt_head = SamCentralMessageAlt.find(:first, :order => "id")
    #@alt_head_parsed = JSON.pretty_generate(JSON.parse(@alt_head.message)) if !@alt_head.nil?
    
    @scm_auth_count = SamCentralMessageAuth.count
    @auth_head = SamCentralMessageAuth.find(:first, :order => "id")
    #@auth_head_parsed = JSON.pretty_generate(JSON.parse(@auth_head.message)) if !@auth_head.nil?
    
    @scm_commander_count = SamCentralMessageCommander.count
    @commander_head = SamCentralMessageCommander.find(:first, :order => "id")
    #@commander_head_parsed = JSON.pretty_generate(JSON.parse(@commander_head.message)) if !@commander_head.nil?
    
    @scm_core_audit_count = SamCentralMessageCoreAudit.count
    @core_audit_head = SamCentralMessageCoreAudit.find(:first, :order => "id")
    #@core_audit_head_parsed = JSON.pretty_generate(JSON.parse(@core_audit_head.message)) if !@core_audit_head.nil?
    
    @scm_core_email_count = SamCentralMessageCoreEmail.count
    @core_email_head = SamCentralMessageCoreEmail.find(:first, :order => "id")
    #@core_email_head_parsed = JSON.pretty_generate(JSON.parse(@core_email_head.message)) if !@core_email_head.nil?
    
    @scm_core_processor_count = SamCentralMessageCoreProcessor.count
    @core_processor_head = SamCentralMessageCoreProcessor.find(:first, :order => "id")
    #@core_processor_head_parsed = JSON.pretty_generate(JSON.parse(@core_processor_head.message)) if !@core_processor_head.nil?
    
    @scm_messaging_count = SamCentralMessageMessaging.count
    @messaging_head = SamCentralMessageMessaging.find(:first, :order => "id")
    #@messaging_head_parsed = JSON.pretty_generate(JSON.parse(@messaging_head.message)) if !@messaging_head.nil?
    
    @scm_tms_temp_out_count = TmsTempOut.count
    @scm_tms_fake_in_count = TmsFakeIn.count
    @scm_csi_temp_out_count = CsiTempOut.count
    @scm_csi_fake_in_count = CsiFakeIn.count
    
    @unprocessed_emails_count = EmailMessage.count(:conditions => ["sent_date is null and ignored_date is null"])
    oldest_unprocessed_email = EmailMessage.find(:first, :select => "generated_date", :conditions => "sent_date IS null AND ignored_date IS null")
    @unprocessed_email_timestamp = oldest_unprocessed_email.generated_date if oldest_unprocessed_email
    
    render(:partial => "message_queue_counter")
  end
  
  private
  
  def load_view_vars
    @prototype_required = true    
  end
  
end
