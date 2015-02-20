class SamServerAddress < ActiveRecord::Base
  belongs_to :sam_server
  set_table_name "sam_server_address"
  belongs_to :state_province
  belongs_to :country
  belongs_to :salutation
  belongs_to :suffix
  belongs_to :job_title
end

# == Schema Information
#
# Table name: sam_server_address
#
#  id                         :integer(10)     not null, primary key
#  sam_server_id              :integer(10)
#  address_line_1             :string(255)
#  address_line_2             :string(255)
#  address_line_3             :string(255)
#  city_name                  :string(255)
#  state_province_id          :integer(10)
#  postal_code                :string(255)
#  country_id                 :integer(10)
#  org_name                   :string(255)
#  org_phone_number           :string(255)
#  salutation_id              :integer(10)
#  first_name                 :string(255)
#  middle_name                :string(255)
#  last_name                  :string(255)
#  suffix_id                  :integer(10)
#  email_address              :string(255)
#  phone_number               :string(255)
#  updated_at                 :datetime        not null
#  created_at                 :datetime        not null
#  change_indicator           :string(7)
#  admin_permission_requested :boolean         default(FALSE), not null
#  job_title_id               :integer(10)     default(17), not null
#  user_id                    :integer(10)
#

