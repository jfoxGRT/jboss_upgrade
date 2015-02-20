class ScEntitlementType < ActiveRecord::Base
  acts_as_cached
  set_table_name "sc_entitlement_type"
  
  @@LEGACY_CODE = "LEG"
  @@OLD_VIRTUAL_CODE = "SAM"
  @@VIRTUAL_CODE = "VIRT"
  @@POST_SC_CODE = "TMS"
    
  def self.LEGACY_CODE
    @@LEGACY_CODE
  end  
    
  def self.VIRTUAL_CODE
    @@VIRTUAL_CODE
  end
  
  def self.old_virtual
    ScEntitlementType.find_by_code(@@OLD_VIRTUAL_CODE)
  end
  
  def self.virtual
    ScEntitlementType.find_by_code(@@VIRTUAL_CODE)
  end
  
  def self.POST_SC_CODE
  	@@POST_SC_CODE
  end
  
  def post_samc?
    @@POST_SC_CODE == self.code
  end
  
end

# == Schema Information
#
# Table name: sc_entitlement_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

