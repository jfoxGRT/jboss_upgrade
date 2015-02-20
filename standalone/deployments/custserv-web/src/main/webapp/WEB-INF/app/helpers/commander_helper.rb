module CommanderHelper

def getEntitlementSum(theSamCustomer, theProduct, theEntitlementType)
  entitlements = Entitlement.find(:all, :select => "sum(license_count) as thesum", 
                                    :conditions => ["sam_customer_id = ? and product_id = ? and sc_entitlement_type_id = ?", 
                                    theSamCustomer.id, theProduct.id, theEntitlementType.id])
 
  (entitlements.length == 0) ? 0 : entitlements[0].thesum
end

def getHostName(pAgent)
  return nil
  #return nil if pAgent.nil?
  #agentSocket = Socket.gethostbyname(pAgent.last_ip)
  return nil if agentSocket.nil?
  return agentSocket[0] if (agentSocket.length > 0)
  return nil
end

end
