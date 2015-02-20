require 'java'
import 'java.lang.Integer'
#import 'sami.scholastic.messaging.message.AgentDiagnosticsRequestMessage'
#import 'sami.scholastic.api.AgentDiagnosticService'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end


class AgentsController < ApplicationController
 
  before_filter :load_agent_and_server, :set_breadcrumb  
  layout 'default'
  
  def index
    @anonymous_agents = Agent.paginate(:page => params[:page], :conditions => ["sam_server_id is null"], 
                                       :order => "created_at desc", :per_page => 15)
  end
  
  def show
    @agent = Agent.find(params[:id])
    @sam_server = @agent.sam_server
    @sam_customer = (@sam_server.nil?) ? nil : (@sam_server.sam_customer)
  end
  
  def edit
    @agent = Agent.find(params[:id])
    @sam_server = @agent.sam_server
    @sam_customer = (@sam_server.nil?) ? nil : (@sam_server.sam_customer)
    #@permissions = Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC, :order => "name")
  end
  
  def diagnostics_index
    @agent = Agent.find(params[:id])
    @sam_server = @agent.sam_server
    @sam_customer = (@sam_server.nil?) ? nil : (@sam_server.sam_customer)
    @show_raw_input = (!params[:spell].nil? && params[:spell]=="apparate") ? true : false
    @is_hosted_server = @agent.sam_server.is_hosted_server? ? true : false
    @has_diag_plugin = false
    if (!@agent.nil? && !@agent.agent_plugins.nil?)
      @agent.agent_plugins.each {|ap|
        #logger.debug("  *** ap.name = #{ap.name},  ap.value = #{ap.value}")
        if (!ap.name.nil? && !ap.value.nil? && ap.name == "diagnostic" && ap.value.to_i > 2)
          @has_diag_plugin = true
        end
      } 
    end
    if (!@has_diag_plugin)
      flash[:notice] = "This agent does not have diagnostic version 2 or greater installed.  Form has been disabled."
      flash[:msg_type] = "error"
    end
    @prev_diags = ConversationInstance.find(:all, 
    					:select => "ci.started as started, ci.completed as completed, crt.name as result",
    					:joins => "ci inner join conversation_result_type crt on ci.result_type_id=crt.id",
    					:conditions => ["agent_id = ? and conversation_identifier = 'execute-diagnostic-command'", @agent.id],
    					:order => "started desc",
    					:limit => 3)
  	if (@prev_diags.length == 0) 
  		@prev_diags = nil
  	end
  end
  
  def update
    #puts "params: #{params.to_yaml}"
    @agent = Agent.find(params[:agent][:id])
    begin
      @agent.unignore_agent_date = DateTime.parse("#{params[:agent][:unignore_agent_date_part].strip} #{params[:agent][:unignore_agent_time_part].strip}")
    rescue Exception
      @agent.unignore_agent_date = nil
    end
    @agent.ignore_agent = params[:agent][:ignore_agent].to_i
    command_chatter_count = params[:agent][:command_chatter_count].strip
    @agent.command_chatter_count = (command_chatter_count.empty?) ? nil : command_chatter_count.to_i
    poll_override = params[:agent][:poll_override].strip
    @agent.poll_override = (poll_override.empty?) ? nil : poll_override.to_i
    begin
      @agent.poll_override_expires_at = DateTime.parse("#{params[:agent][:poll_override_expires_at_date].strip} #{params[:agent][:poll_override_expires_at_time].strip}")
    rescue Exception
      @agent.poll_override_expires_at = nil
    end
    @agent.save!
    flash[:notice] = "Agent successfully updated"
    flash[:msg_type] = "info"
    redirect_to(:action => :show, :id => @agent.id)
  end
  
  # Schedule agent diagnostic
  # - Parse form fields and call java service to schedule agent diagnostics
  # - See following for additional commands and params
  #    ~ sami.shared.diagnostic.DiagnosticPluginConstants
  #    ~ sami.scholastic.api.SimpleConversationInstanceService
  #
  def schedule_diagnostic
    @agent = Agent.find(params[:agent_id])    
       
    if (!params[:reset].nil?)
        flash[:notice] = "Form has been cleared"
        flash[:msg_type] = "info"   
        redirect_to(:action => :diagnostics_index, :id => @agent.id)  
        return
    end
    
    cmdStrings = Array.new
    retStrings = Array.new    
    diag_service = SC.getBean("agentDiagnosticService")
    
    #logger.debug(" PARAMS: ")
    #params.each {|k,v| logger.debug("    * #{k} = #{v}") }
    
    # -----------------
    # Maintenance Note: If you update paths below, please also update tool tip in user's form in diagnostics_index 
    # -----------------  
    if (!params[:AgentFiles].nil?)
      logger.debug("   --x> DOING AgentFiles ")
      cmdStrings << "relativePath===log/sami.log*|||commandId===fetchagentfile"
      cmdStrings << "relativePath===conf/*.xml|||commandId===fetchagentfile"
      cmdStrings << "relativePath===conf/*.properties|||commandId===fetchagentfile"      
    end
    if (!params[:SSPropFiles].nil?)
      logger.debug("   --x> DOING SSPropFiles ")
      cmdStrings << "relativePath===*.properties|||commandId===fetchsamserverfile"    
    end
    if (!params[:SSInstallLogFiles].nil?)
      logger.debug("   --x> DOING SSInstallLogFiles ")
      cmdStrings << "relativePath===*InstallLog.log|||commandId===fetchsamserverfile"  #older installations    
      cmdStrings << "relativePath===log/*Install*|||commandId===fetchsamserverfile"    #more recent installations
    end            
    if (!params[:MySQLTables].nil?)
      logger.debug("   --x> DOING MySQLTables ")
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select now() now;"
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select * from slms_samcentral;"
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select * from slms_server_assets;"
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select * from slms_sam_connect_cache;"                  
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select * from ic_community;"
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select * from src_quiz;"
      ## Bug exists in core v39 (and previous versions) with jdbcservice where a text field with null will bork a
      ##   fetchsamserverqueryresults query.  command gracefully fails and next command is run.  In local testing,
      ##   table ic_community had 2 columns with null data, and src_quiz had 1 column with null data.  The following
      ##   cmdStrings avoid those columns. If other columns are null in beta or production, the command will gracefully
      ##   fail, so no larger issue other than not getting a diagnostic output for a specific command.
      ##   Fix has been made to the core plugin; will be fixed with core v40.
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select COMMUNITY_ID, INSTALLATION_ID, DOMAIN_ID, ORGANIZATION_ID, NAME, PATH, INHERIT_STYLES, LAUNCH_FRAME, START_PAGE, LOGIN_PAGE, HUB_PAGE, USE_HTTP_SESSION, LOG_LOGINS, LOG_FAILED_LOGINS, LOG_CLIENT_INFO, SYSTEM_DELIVERED, IS_ENABLED, IS_DELETABLE from ic_community;"      
      cmdStrings << "relativePath===|||commandId===fetchsamserverqueryresults|||instructions===select quiz_id, book_id, version_num, active, comments, collection_name, teacher_made from src_quiz;"                
    end    
    if (!params[:MySQLFiles].nil?)
      logger.debug("   --x> DOING MySQLFiles ")
      cmdStrings << "relativePath===log/*mysql*|||commandId===fetchsamserverfile"                
      cmdStrings << "relativePath===mysql/my.cnf|||commandId===fetchsamserverfile"                      
    end    
    if (!params[:JBossLog].nil?)
      logger.debug("   --x> DOING JBossLog ")
      cmdStrings << "relativePath===jboss/server/lycea/log/server.log|||commandId===fetchsamserverfile"
      cmdStrings << "relativePath===jboss/scholastic/log/server.log|||commandId===fetchsamserverfile"  
      cmdStrings << "relativePath===log/*jboss*|||commandId===fetchsamserverfile" 
    end
    if (!params[:RawCommandCheckbox].nil?)
      logger.debug("   --x> DOING RawCommandString ")
      cmd = params[:RawCommandString].strip
      logger.debug("       *** Raw Command String: --#{cmd}--")
      if (!cmd.nil? && cmd.length > 0)
        cmdStrings << cmd
      end
    end    

    logger.info(" --x> Just before diag_service.scheduleAgentDiagnostic call:  @agent.id = #{@agent.id}")
    
    if (cmdStrings.length == 0)
       logger.info(" --x> NOT DOING IT ... cmdString length invalid (length = #{cmdStrings.length})")    
       flash[:notice] = "You need to select at least one checkbox to schedule agent diagnostics"
       flash[:msg_type] = "error"               
       redirect_to(:action => :diagnostics_index, :id => @agent.id)             
       return
    end
    
    logger.info(" --x> Just before diag_service.scheduleAgentDiagnostic call:  cmdStrings = #{cmdStrings}")    
    retStrings = diag_service.scheduleAgentDiagnostic(@agent.id, cmdStrings)

    #Check for array with 2+ elements with element 0 being error code true (value "1") to indicate service error
    if (!retStrings.nil? && retStrings.length > 1 && retStrings[0]=="1")
        flash[:notice] = retStrings[2]
        flash[:msg_type] = "error"        
    else
        flash[:notice] = "Diagnostics for agent #{@agent.id} has been scheduled"
        flash[:msg_type] = "info"        
    end
    redirect_to(:action => :diagnostics_index, :id => @agent.id)      
    
    rescue Exception => e
      logger.info("ERROR: #{e}")
      flash[:notice] = "Your request to schedule diagnostics for agent #{@agent.id} was unsuccessful: #{e}"
      redirect_to(:action => :diagnostics_index, :id => @agent.id)
    
  end
  
  #################
  # AJAX ROUTINES #
  #################
    
  def update_anonymous_agent_table
    @anonymous_agents = Agent.paginate(:page => params[:page], :conditions => ["sam_server_id is null"], 
                                       :order => anonymous_agent_sort_by_param(params["sort"]), :per_page => 15)
    render(:partial => "anonymous_agent_info", 
           :locals => {:agent_collection => @anonymous_agents,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :sam_customer_id => params[:id]}, :layout => false)
  end
  
  protected
  
  def load_agent_and_server
    if(params[:agent_id])
      @agent = Agent.find(params[:agent_id])
      @sam_server = @agent.sam_server
      @sam_customer = @sam_server.sam_customer if @sam_server
    end
  end
  
  private
  
  def anonymous_agent_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "agent_id" then "id"
      when "date_created" then "created_at"
      when "date_updated" then "updated_at"
      when "last_ip_address" then "last_ip"
      when "cookie" then "cookie"
      when "cookie_verified" then "cookie_verified"
      when "jre_version" then "jre_version"
      when "microloader_version" then "microloader_version"
      when "os_series" then "os_series"
      when "next_poll_at" then "next_poll_at"
      when "cpu_bits" then "cpu_bits"
      when "os_family" then "os_family"
      when "cpu_type" then "cpu_type"
      when "last_verified_cookie" then "last_verified_cookie"
      
      when "agent_id_reverse" then "id desc"
      when "date_created_reverse" then "created_at desc"
      when "date_updated_reverse" then "updated_at desc"
      when "last_ip_address_reverse" then "last_ip desc"
      when "cookie_reverse" then "cookie desc"
      when "cookie_verified_reverse" then "cookie_verified desc"
      when "jre_version_reverse" then "jre_version desc"
      when "microloader_version_reverse" then "microloader_version desc"
      when "os_series_reverse" then "os_series desc"
      when "next_poll_at_reverse" then "next_poll_at desc"
      when "cpu_bits_reverse" then "cpu_bits desc"
      when "os_family_reverse" then "os_family desc"
      when "cpu_type_reverse" then "cpu_type desc"
      when "last_verified_cookie_reverse" then "last_verified_cookie desc"
      else "created_at desc"
    end
  end
  
  def set_breadcrumb
    @site_area_code = SAM_SERVERS_CODE
  end
  
end
