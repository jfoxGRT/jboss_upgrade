require 'entitlement_manager/defaultDriver'

class CustomerServiceAdminController < ApplicationController

# IS THIS CONTROLLER USED? THE LAYOUT BELOW IS NOT IN THE SYSTEM???
layout "customer_service_admin"

def index
end

def org_state_districts

  simpler_query = "select org.* from org, customer_address ca, state_province sp " +
                  "where ca.customer_id = org.customer_id and ca.state_province_id = sp.id and sp.id = " + params[:id] + " " +
                  "and org.top_level_org_id is null order by org.name"
  @open_top_level_orgs = Org.find_by_sql(simpler_query)
  @schools = []
  @districts = []
  @open_top_level_orgs.each do |otlo|
    noChildren = true
    otlo.customer.child_relationships.each do |rel|
      if (activeOrgRelationship?(rel))
        noChildren = false
      end
    end
    if (noChildren == true)
      @schools << otlo
    else
      @districts << otlo
    end
  end


  #query = "select distinct cr.related_customer_id, org.name " +
  #        "from customer_relationship cr, customer_address ca, state_province sp, org " +
  #        "where org.customer_id = cr.related_customer_id and " +
  #        "ca.customer_id = cr.related_customer_id and " + 
  #        "ca.state_province_id = sp.id and " +
  #        "sp.id = " + params[:id] + " and " +
  #        "(cr.related_customer_id not in (select distinct customer_id from customer_relationship)) order by org.name"
  @state = StateProvince.find(params[:id])
  #@open_top_district_relationships = CustomerRelationship.find_by_sql(query)
  #t = Time.now
  #puts "Built org tree.. "  + t.strftime("%I:%M:%S.") + t.usec.to_s
end

def org_states
  @states_by_country = []
  @countries = Country.find(:all, :order => "name");
  i = 0
  @countries.each do |c|
      @states_by_country[i] = []
      @states_by_country[i] = StateProvince.find(:all, :joins => "as sp inner join country as c on sp.country_id = c.id",
                                                :select => "sp.*", :conditions => ["c.id = ?", c.id], :order => "sp.name");
      i += 1
  end
  puts @states_by_country.length.to_s
  puts @states_by_country[0][0].class.to_s
end

def org_hierarchy
  
  #@state_name = params[:state_name]
  #@state_id = params[:state_id]
  
  @org = Org.find(params[:id])
  @org.customer.customer_addresses
  @org_child_relationships = CustomerRelationship.find(:all, :conditions => ["related_customer_id = ?", params[:id]],
                                                 :joins => "as cr inner join org on cr.related_customer_id = org.customer_id",
                                                 :select => "cr.*", :order => "org.name")
  @subdistricts = []
  @schools = []
  @org_child_relationships.each do |dc|
    if (!dc.customer.child_relationships.nil? && dc.customer.child_relationships.length > 0)
      @subdistricts << dc.customer.org
    else
      @schools << dc.customer.org
    end
  end
  
  @subdistricts = @subdistricts.sort {|x,y| x.name <=> y.name}
  @schools = @schools.sort {|x,y| x.name <=> y.name}
  
  # Populate the breadcrumb array
  @breadcrumb_path = getBreadcrumbArray(@org)
  
end

def org_details

  if (params[:id].nil?)
    render(:text => "This page requires an Organization ID as a URL parameter:    /" + controller_name + "/org_details/?")
    return
  end
  
  @org = Org.find(params[:id])
  @addresses = @org.customer.customer_addresses
  @phone_nums = @org.customer.telephones
  
  # Populate the breadcrumb array
  @breadcrumb_path = getBreadcrumbArray(@org)
  
  districtType = CustomerGroup.find_by_code("D")
  if (@org.customer.customer_group == districtType)
  
    # Get the entitlements tied to this organization
    @entitlements = Entitlement.find(:all, :conditions => ["root_org_id = ?", params[:id]], :order => "ordered")
  
    # Get the servers installed for this organization
    @servers = SamServer.find(:all, :conditions => ["root_org_id = ?", params[:id]], :order => "created_at")
  
  
    # Get the seats from the entitlements array
    @seats = []
    @entitlements.each do |e|
      e.seats.each do |s|
        @seats << s
      end
    end
    @seats_by_entitlement_server = build_hash_from_array(@seats, "entitlement_id", "sam_server_id")
  end
end

def update_root_org
  
  entitlementManager = EntitlementManager::EntitlementManagerPortType.new( ENTITLEMENT_MANAGER_URL )
  
  param = EntitlementManager::UpdateRootOrg.new
  param.entitlementId = 2
  param.orgId = 5
    
  result = entitlementManager.updateRootOrg( param )
  
end

private

def getBreadcrumbArray(theOrg)
  back_to_top = []
  next_org = theOrg
  back_to_top << next_org
  while (!(next_org.customer.parent_relationships.nil?) && next_org.customer.parent_relationships.length > 0)
    next_org = next_org.customer.parent_relationships[0].related_customer.org
    back_to_top << next_org
    unless (next_org.customer.parent_relationships.nil?)
      puts "Number of parent relationships: " + next_org.customer.parent_relationships.length.to_s
    end
  end
  breadcrumb_array = back_to_top.reverse
  puts "Length of Breadcrumb array: " + breadcrumb_array.length.to_s
  return breadcrumb_array
end

def activeOrgRelationship?(rel)
      sup2subCat = RelationshipCategory.find_by_description("SUP2SUB")
      if ((rel.customer != nil) && (rel.related_customer != nil) && (rel.customer != rel.related_customer) &&
           (rel.effective <= Date.today) && (rel.relationship_category == sup2subCat) && 
           ((rel.end.nil?) || (rel.end > Date.today)))
           return true
      end
      return false
end

def build_tree_map(relationships, cust, index1, index2, first_indicator)
  
  if (first_indicator == 1)
    relationships.each do |top_level_rel|
      index1 = build_tree_map(relationships, top_level_rel.related_customer, index1 + 1, 0, 0)
    end
  else
    @org_tree[index1] = Array.new
    @org_tree[index1][index2] = cust
    parent_index = index1
    cust.child_relationships.each do |child_rel|
      index1 = build_tree_map(relationships, child_rel.customer, index1 + 1, parent_index, 0)
    end
  end
  return index1
end

def build_hash_from_array(the_array, *args)
  the_hash = {}
  the_array.each do |element|
    hash_value = element.attributes(:only => args)
    #puts hash_value
    if (the_hash[hash_value.to_s].nil?)
      the_hash[hash_value.to_s] = []
    end
    the_hash[hash_value.to_s] << element
  end
  return the_hash
end

end
