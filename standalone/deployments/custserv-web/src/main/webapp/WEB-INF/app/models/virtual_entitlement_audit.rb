class VirtualEntitlementAudit < ActiveRecord::Base
  set_table_name "virtual_entitlement_audit"
  belongs_to :entitlement
  belongs_to :user
  belongs_to :sam_server
end

# == Schema Information
#
# Table name: virtual_entitlement_audit
#
#  id             :integer(10)     not null, primary key
#  time_created   :datetime
#  entitlement_id :integer(10)     not null
#  license_count  :integer(10)     default(0), not null
#  reason_code    :string(255)     default("UNK"), not null
#  user_id        :integer(10)
#  user_comment   :text
#  sam_server_id  :integer(10)
#

