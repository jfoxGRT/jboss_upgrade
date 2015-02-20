require "sam_util/destroy"

class CommanderAdminController < ApplicationController

  layout "cs_layout"

  def index
  end
  
  def agent_details
    @agent = Agent.find( params[:id] )
    @recent_conversations = ConversationInstance.find( :all, :conditions => ["agent_id = ?", @agent.id], :order => "started desc")
  end
  
  def delete_agent
    SamUtil::DestroyAgent.execute( params[:id] )
  end

  def delete_conversation_instance
    @conversation_instance_id = params[:id]
    SamUtil::DestroyConversationInstance.execute( @conversation_instance_id )
  end

  def conversation_details
    @conversation_instance = ConversationInstance.find( params[:id] )
  end
  
  def command_details
    @conversation_command = ConversationCommand.find( params[:id] )
  end

  def organization_detail
    @organization = Org.find( params[:id] )
    @users = @organization.users
  end

  def server_detail
    @sam_server = SamServer.find( params[:id] )
  end

  def delete_server
    SamUtil::DestroyServer.execute( params[:id] )
  end

  def user_detail
    @user = SamCustomerUser.find( params[:id] )
  end

  def delete_user
    SamUtil::DestroyUser.execute( params[:id] )
  end

  def create_user
    @org = Org.find( params[:org_id] )
    @user = SamCustomerUser.new(params[:user])
    @orgRole = SamCustomerUserOrgRole.new
    @orgRole.org = @org
    @orgRole.sam_customer_role = SamCustomerRole.find(:first, :conditions => "code = 'USER'")
    @user.save
    @orgRole.sam_customer_user = @user
    @orgRole.save
    redirect_to :action => :user_detail, :id => @user.id
  end
  
  def assign_administrator
    @sam_customer_user = SamCustomerUser.find( params[:administrator_user_id] )
    @sam_server = SamServer.find( params[:sam_server_id])
    @sam_server_administrator = SamServerAdministrator.new
    @sam_server_administrator.sam_server = @sam_server
    @sam_server_administrator.sam_customer_user = @sam_customer_user
    @sam_server_administrator.save
    redirect_to :action => "server_detail", :id => @sam_server.id
  end
  
  def remove_admin
    @sam_server_administrator = SamServerAdministrator.find( params[:id] )
    @sam_server = @sam_server_administrator.sam_server
    SamServerAdministrator.delete( @sam_server_administrator.id )
    redirect_to :action => "server_detail", :id => @sam_server.id
  end
  
  def assign_server_organization
    @org = Org.find( params[:org_id])
    @sam_server = SamServer.find( params[:sam_server_id])
    @sam_server.orgs << @org
    @sam_server.save
    redirect_to :action => "server_detail", :id => @sam_server.id    
  end

  def remove_server_org
    @org = Org.find( params[:id])
    @sam_server = SamServer.find( params[:sam_server_id] )
    @sam_server.orgs.delete( @org )
    @sam_server.save
    redirect_to :action => "server_detail", :id => @sam_server.id
  end
end
