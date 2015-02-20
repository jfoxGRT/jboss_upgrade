class EntitlementKnownDestination < ActiveRecord::Base
  set_table_name "entitlement_known_destinations"
  belongs_to :bill_to_org, :class_name => "Org", :foreign_key => "org1_id"
  belongs_to :ship_to_org, :class_name => "Org", :foreign_key => "org2_id"
  belongs_to :sam_customer
  belongs_to :entitlement
  
  
  
  def bill_to_ucn
    if (bill_to_org.nil?)
      nil
    else
      self.bill_to_org.customer.ucn
    end
  end
  
  def bill_to_ucn=(ucn)
    self.bill_to_org = Org.find_by_ucn(ucn)    
  end
  
  def ship_to_ucn
    if (ship_to_org.nil?)
      nil
    else
      self.ship_to_org.customer.ucn
    end
  end
  
  def ship_to_ucn=(ucn)
    self.ship_to_org = Org.find_by_ucn(ucn)
  end
  
  def self.find_by_orgs(org_1, org_2)
    return nil if (org_1.nil? || org_2.nil?)
    EntitlementKnownDestination.find(:first, :conditions => ["org1_id = ? and org2_id = ?", org_1.id, org_2.id])
  end
  
  def validate
    errors.add("Bill-to UCN", " is not valid") if bill_to_org.nil?
    errors.add("Ship-to UCN", " is not valid") if ship_to_org.nil?
  end
  
  def self.retrieve_by_entitlement(entitlement)
    return find(:all, :conditions => ["entitlement_id = ?", entitlement.id])
  end
  
  def self.delete_by_entitlement(entitlement)
    delete_all(["entitlement_id = ?", entitlement.id])
  end
  
end

# == Schema Information
#
# Table name: entitlement_known_destinations
#
#  id              :integer(10)     not null, primary key
#  org1_id         :integer(10)     not null
#  org2_id         :integer(10)     not null
#  sam_customer_id :integer(10)     not null
#  entitlement_id  :integer(10)
#

