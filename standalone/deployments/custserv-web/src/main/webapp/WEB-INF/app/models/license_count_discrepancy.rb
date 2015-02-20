class LicenseCountDiscrepancy < ActiveRecord::Base
  set_table_name "license_count_discrepancies"
  belongs_to :sam_server
  belongs_to :subcommunity  
end

# == Schema Information
#
# Table name: license_count_discrepancies
#
#  id               :integer(10)     not null, primary key
#  created_at       :datetime
#  sam_server_id    :integer(10)     not null
#  subcommunity_id  :integer(10)     not null
#  sam_server_count :integer(10)     not null
#  seat_pool_count  :integer(10)     not null
#  entitlement_id   :integer(10)
#

