class AuthZonesController < ApplicationController

  layout "default_with_utilities_subtabs"
  def index
    @auth_zones = AuthZone.find(:all)
  end

  # Renders form to allow new auth zone entry
  def create_zone
    render(:partial => 'auth_zones/auth_zone_create_form')
  end
  
  # Renders form to allow for editing an auth zone's information
  def edit_zone
    @auth_zone_edit = AuthZone.find(params[:id])
    render(:partial => 'auth_zones/auth_zone_edit_form', :locals => {:auth_zone_edit => @auth_zone_edit, :auth_zone_id => params[:id]})
  end

  # Renders form to allow for viewing an auth zone's information
  def view_zone
    @auth_zone_view = AuthZone.find(params[:id])
    render(:partial => 'auth_zones/auth_zone_view_form', :locals => {:auth_zone_view => @auth_zone_view, :auth_zone_id => params[:id]})
  end

  # Delete an auth zone
  def delete_auth_zone
    auth_zone_code = AuthZone.find(params[:id]).code
    AuthZone.destroy(params[:id])
    flash[:notice] = auth_zone_code + " Auth Zone has been deleted"
    redirect_to(:action => :index)
  end

  # Handles the final step in creating/updating auth zone info
  def update_create_auth_zone
    message_append = ""
    if(params[:mode] == "Create")
      auth_zone = AuthZone.new
      auth_zone.created_at = Time.now
      message_append = "created." # used for differing messages for creating/updating
    elsif(params[:mode] == "Update")
      auth_zone = AuthZone.first(:conditions => ["auth_zone.id = ?", params[:id]])
      message_append = "updated." # used for differing messages for creating/updating
    else
      logger.debug "Invalid mode."
      break
    end

    auth_zone.updated_at = Time.now
    # Null tests are done to be safe - not truly necessary
    if(params[:code])
      auth_zone.code = params[:code]
    end
    
    if(params[:desc])
      auth_zone.desc = params[:desc]
    end
    
    if(params[:login_path])
      auth_zone.login_path = params[:login_path]
    end    
    
    if(params[:error_path])
      auth_zone.error_path = params[:error_path]
    end
    
    if(params[:zone_password])
      auth_zone.password = params[:zone_password]
    end
    
    if(params[:login_url])
      auth_zone.url = params[:login_url]
    end

    if(params[:root_url])
      auth_zone.root_url = params[:root_url]
    end
    
    if(params[:logout_url])
      auth_zone.logout_url = params[:logout_url]
    end
    
    if(params[:usage_url])
      auth_zone.usage_url = params[:usage_url]
    end
    
    if(params[:saml_url] && params[:saml_url] != "")
      auth_zone.saml_url = params[:saml_url]
    end
    
    auth_zone.save

    flash[:notice] = params[:code] + " Auth Zone has been " + message_append
    redirect_to(:action => :index)
  end

end

