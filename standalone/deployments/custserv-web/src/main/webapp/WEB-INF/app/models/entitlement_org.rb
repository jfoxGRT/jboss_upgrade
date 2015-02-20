class EntitlementOrg < ActiveRecord::Base
  set_table_name "entitlement_org"
  belongs_to :entitlement_org_type
  belongs_to :entitlement
  belongs_to :org
end

# == Schema Information
#
# Table name: entitlement_org
#
#  id                      :integer(10)     not null, primary key
#  entitlement_id          :integer(10)     not null
#  entitlement_org_type_id :integer(10)     not null
#  name                    :string(255)
#  ucn                     :string(255)
#  org_id                  :integer(10)     not null
#

