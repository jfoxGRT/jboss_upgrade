class EntitlementOrgType < ActiveRecord::Base
  acts_as_cached
  set_table_name "entitlement_org_type"
  
  @@BILL_TO_CODE = 'B'
  @@SHIP_TO_CODE = 'S'
  
  def self.BILL_TO_CODE
    @@BILL_TO_CODE
  end
  
  def self.SHIP_TO_CODE
    @@SHIP_TO_CODE
  end
  
  
  def self.shipTo
    EntitlementOrgType.find_by_code("S")
  end  
  
  def self.billTo
    EntitlementOrgType.find_by_code("B")
  end
  
end

# == Schema Information
#
# Table name: entitlement_org_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

