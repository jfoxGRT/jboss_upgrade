class EntitlementAudit < ActiveRecord::Base
  set_table_name "entitlement_audit"
  
  def self.get_current_by_sam_customer_id_and_product_id(sam_customer_id, product_id)
    EntitlementAudit.find(:all, :select => "ea.*", 
                          :joins => "ea inner join entitlement e on ea.entitlement_id = e.id",
                          :conditions => ["e.sam_customer_id = ? and e.product_id = ? and ea.licensing_activation_id is null", sam_customer_id, product_id])
  end
  
  def self.apply_new_licensing_activation(sam_customer, user)
    
    licensing_activation_record = LicensingActivation.create(:sam_customer => sam_customer, :user => user)    
    entitlement_audit_records = EntitlementAudit.find(:all, :select => "entitlement_audit.*", :joins => "inner join entitlement on entitlement_audit.entitlement_id = entitlement.id", 
                                                    :conditions => ["entitlement_audit.licensing_activation_id is null and entitlement.sam_customer_id = ?", sam_customer.id])
    entitlement_audit_records.each do |ear|
      ear.licensing_activation = licensing_activation_record
      ear.save!
    end
  end
  
  
end

# == Schema Information
#
# Table name: entitlement_audit
#
#  id                 :integer(10)     not null, primary key
#  entitlementid      :integer(10)     default(-1), not null
#  created_at         :datetime
#  old_sam_customerid :integer(10)
#  new_sam_customerid :integer(10)
#  old_license_count  :integer(10)
#  new_license_count  :integer(10)
#  old_active         :boolean
#  new_active         :boolean
#

