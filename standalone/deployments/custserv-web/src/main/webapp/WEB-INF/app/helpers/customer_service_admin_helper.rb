module CustomerServiceAdminHelper

def getSubdistricts(theOrg)
  districtGroupType = CustomerGroup.find_by_code("D")
  subs = Org.find(:all, :joins => "inner join customer on org.customer_id = customer.id", 
                  :conditions => ["org.top_level_org_id = ? and customer.customer_group_id = ?", theOrg.id, districtGroupType.id])
  return subs
end

def getSchools(theOrg)
  districtGroupType = CustomerGroup.find_by_code("S")
  subs = Org.find(:all, :joins => "inner join customer on org.customer_id = customer.id", 
                  :conditions => ["org.top_level_org_id = ? and customer.customer_group_id = ?", theOrg.id, districtGroupType.id])
  return subs
end

def isUsingSamCentral?(theOrg)
  sc = SamCustomer.find(:first, :conditions => ["root_org_id = ?", theOrg.id])
  if (sc.nil?)
    return false;
  else
    return true;
  end
end

def getServers(theOrg)
  servers = SamServer.find(:all, :conditions => ["root_org_id = ?", theOrg.id])
  return servers
end

def isDistrictLevel?(theOrg)
  district = CustomerGroup.find_by_code("D")
  if (theOrg.customer.customer_group == district)
    return true;
  else
    return false;
  end  
end

def getEntitlementOrg(ent, eo_desc)
  # Get the bill-to and ship-to orgs
  if (eo_desc == "bill_to")
    eo_type = EntitlementOrgType.find_by_code("B")
  elsif (eo_desc == "ship_to")
    eo_type = EntitlementOrgType.find_by_code("S")
  else
    return nil
  end
  ent.entitlement_orgs.each do |eo|
    if (eo.entitlement_org_type == eo_type)
      return ((Customer.find(:first, :conditions => ["ucn = ?", eo.ucn])).org)
    end
  end
  return nil
end

def hasChildren
end


end