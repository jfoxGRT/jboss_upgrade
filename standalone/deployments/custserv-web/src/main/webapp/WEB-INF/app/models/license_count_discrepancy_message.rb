class LicenseCountDiscrepancyMessage < ActiveRecord::Base
  
  set_table_name 'license_count_discrepancy_messages'
  belongs_to :license_count_discrepancies
  
end