module TasksHelper
	
	def eligible_for_reopen?(task_type_code)
		return (task_type_code == TaskType.UNASSIGNED_ENTITLEMENT_CODE)
	end
  
  def org_is_selectable(ai, o)
    alert_code = ai.alert.code
    ((alert_code == Alert.UNASSIGNED_ENTITLEMENT_CODE) && open?(o)) ||
    ((alert_code != Alert.UNASSIGNED_ENTITLEMENT_CODE) && open?(o) && o.sam_customer.nil?)
  end
  
  def open?(theOrg)
    openStatus = CustomerStatus.find_by_code("01")
    return (theOrg.customer.customer_status == openStatus)
  end
  
  def using_sam_connect?(o)
    sc = SamCustomer.find(:first, :conditions => ["root_org_id = ?", o.id])
    (sc.nil?) ? false : sc
  end
  
  def get_main_phone_number(org)
  main_phone_type = TelephoneType.find_by_code("05")
  phone_nums = org.customer.telephones
  phone_nums.each do |pn|
    if (pn.telephone_type == main_phone_type)
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
  
  def get_sc_licensing_activated_date(sam_customer)
    ldate = sam_customer.sc_licensing_activated
    return "a month from now" if ldate.nil?
    ready_date = Date.new(ldate.year(), ldate.mon() + 1, ldate.day())
    return (ready_date.strftime(fmt='%x'))
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
