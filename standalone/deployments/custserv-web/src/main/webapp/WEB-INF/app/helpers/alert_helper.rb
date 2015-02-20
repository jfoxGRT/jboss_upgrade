module AlertHelper

def getMainPhoneNumber(theOrg)
  mainPhoneType = TelephoneType.find_by_code("05")
  phoneNums = theOrg.customer.telephones
  phoneNums.each do |pn|
    if (pn.telephone_type == mainPhoneType)
      return pn
    end
  end
  return nil
end

def getSubdistricts(theOrg)
  districtGroupType = CustomerGroup.find_by_code("D")
  internalOrg = Customer.find_by_ucn(-1).org
  if (theOrg.top_level_orgs[0] == internalOrg)
    subs = Org.find(:all, :from => "org, top_level_org as tlo, customer as c",
                  :conditions => ["tlo.org_id = org.id and tlo.top_level_org_id = ? and org.customer_id = c.id and c.customer_group_id = ?", theOrg.id, districtGroupType.id])
  else
    distList = []
    subs = findLowerOrgsByType(theOrg, distList, districtGroupType)
  end
  return subs
end

def getSamCustomerCutoverDate(samCustomer)
  regDate = samCustomer.cutover_date
  return "a month from now" if regDate.nil?
  fullyRegDate = Date.new(regDate.year(), regDate.mon() + 1, regDate.day())
  return (fullyRegDate.strftime(fmt='%x'))
end

def getSchools(theOrg)
  schoolGroupType = CustomerGroup.find_by_code("S")
  internalOrg = Customer.find_by_ucn(-1).org
  if (theOrg.top_level_orgs[0] == internalOrg)
    schools = Org.find(:all, :from => "org, top_level_org as tlo, customer as c",
                  :conditions => ["tlo.org_id = org.id and tlo.top_level_org_id = ? and org.customer_id = c.id and c.customer_group_id = ?", theOrg.id, schoolGroupType.id])
  else
    schoolList = []
    schools = findLowerOrgsByType(theOrg, schoolList, schoolGroupType)
  end
  return schools
end

def findLowerOrgsByType(org, theList, theGroup)
  getActiveChildRelationships(org).each do |rel|
    if (rel.customer.customer_group == theGroup)
      theList << rel.customer.org
    end
    findLowerOrgsByType(rel.customer.org, theList, theGroup)
  end
  return theList
end

def isUsingSamCentral?(theOrg)
  sc = SamCustomer.find(:first, :conditions => ["root_org_id = ?", theOrg.id])
  if (sc.nil?)
    return false;
  else
    return sc;
  end
end

def getServers(theSc)
  servers = SamServer.find(:all, :conditions => ["sam_customer_id = ?", theSc.id])
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

def isOpen?(theOrg)
  openStatus = CustomerStatus.find_by_code("01")
  return (theOrg.customer.customer_status == openStatus)
end


def orgIsSelectable(theAlertInstance, theOrg)
  ueAlert = Alert.getUnassignedEntitlementsAlert
  ((theAlertInstance.alert == ueAlert) && isOpen?(theOrg)) ||
  ((theAlertInstance.alert != ueAlert) && isOpen?(theOrg) && theOrg.sam_customer.nil?)
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

  def isActiveParentRelationship?(rel)
    sup2subCat = RelationshipCategory.find_by_description("SUP2SUB")
    if ((rel.related_customer != nil) && (rel.customer != rel.related_customer) && (rel.effective <= Date.today) && 
       (rel.relationship_category == sup2subCat) && ((rel.end.nil?) || (rel.end > Date.today)))
       return true
    end
    return false
  end

  def getActiveChildRelationships(theOrg)
    relList = []
    theOrg.customer.child_relationships.each do |rel|
      if (isActiveParentRelationship?(rel))
        relList << rel
      end
    end
    return relList
  end

end
