module CsiHelper

  def partitionOrgsByCategory(pState, pTlos, pDistricts, pSchools)
    internalOrg = Org.getInternalOrg
    pCustomers = Customer.getByStateProvinceCountryCodes(pState.code, pState.country.code)
    pCustomers.each do |c|
      if (c.org.top_level_orgs[0] == internalOrg)
        pTlos << c.org
      end
      if (isDistrict?(c))
        pDistricts << c.org
      end
      if (isSchool?(c))
        pSchools << c.org
      end
    end
    return pCustomers
  end
  
  def isDistrict?(cust)
    districtGroup = CustomerGroup.find_by_code("D")
    return (cust.customer_group == districtGroup)
  end
  
  def isSchool?(cust)
    schoolGroup = CustomerGroup.find_by_code("S")
    return (cust.customer_group == schoolGroup)
  end 
  
end
