class LicensingActivation < ActiveRecord::Base
  set_table_name "licensing_activation"
  
  belongs_to :sam_customer
  belongs_to :user
  has_many :entitlement_audits
  
end

# == Schema Information
#
# Table name: licensing_activation
#
#  id              :integer(10)     not null, primary key
#  sam_customer_id :integer(10)     not null
#  created_at      :datetime
#  user_id         :integer(10)     not null
#

