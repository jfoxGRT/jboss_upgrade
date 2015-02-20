require 'user_manager/defaultDriver'

class UpdatesController < ApplicationController

include UserManager

layout 'new_layout_with_jeff_stuff', :except => [:global_toggle, :search_customer]

def overrides
  @update_manager = UpdateManager.getGlobalRecord()
  @customer_overrides = UpdateManager.getCustomerOverrides()
  @server_overrides = UpdateManager.getServerOverrides()
end

def global_toggle 
  @update_manager = UpdateManager.getGlobalRecord()
  @update_manager.active = (@update_manager.active == 1 ? 0 : 1)
  @update_manager.save!   
end

def add_customer_override_p1
  render( :layout => "wizard" )
end

def add_customer_override_p2
  @sam_customer = SamCustomer.find( params[:id] ) 
  render( :layout => "wizard" )
end

def search_customer
  @search_name = params[:search_name]
  if @search_name.length >= 3 
    @search_customers = SamCustomer.find_by_keystring( @search_name )
  end

end

def add_exception
  update_manager = UpdateManager.new
  if params.has_key?(:active)
    update_manager.active = params[:active].to_i
  else
    update_manager.active = 0
  end
  if params.has_key?(:sam_customer_id)
    update_manager.sam_customer_id = params[:sam_customer_id]
  end
  if params.has_key?(:sam_server_id)
    update_manager.sam_server_id = params[:sam_server_id]
  end
  update_manager.save!
end

def remove_exception
  UpdateManager.delete(params[:id])
end

def toggle_exception
  um = UpdateManager.find(params[:id])
  um.active = (-1 * um.active) + 1;
  um.save!
end

  def request_agent_component_reinstall
    if (params[:agent_id] and !params[:agent_id].empty? and params[:managed_component_code] and !params[:managed_component_code].empty?)
      existing_requests = AgentComponentReinstallRequest.find(:first, :conditions => ["agent_id = ? AND managed_component_code = ? ", params[:agent_id], params[:managed_component_code]])
      
      if(existing_requests.nil?) #if the request doesn't already exist
        new_request = AgentComponentReinstallRequest.new(:agent_id => params[:agent_id].to_i, :managed_component_code => params[:managed_component_code])
        new_request.save
      end
    end
    
    render(:partial => "/common/flash_area", :locals => {:flash_notice => "Master Pack Request Successful.", :flash_type => "info"}, :layout => false)
  end

end