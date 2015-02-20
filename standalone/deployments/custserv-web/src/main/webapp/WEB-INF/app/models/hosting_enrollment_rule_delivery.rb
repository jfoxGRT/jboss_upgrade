class HostingEnrollmentRuleDelivery < ActiveRecord::Base
  set_table_name "hosting_enrollment_rule_delivery"
  
  has_many :entitlements
  has_many :sam_servers

end