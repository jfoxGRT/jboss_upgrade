class CustomerAddress < ActiveRecord::Base
  set_table_name "customer_address"
  belongs_to :country
  belongs_to :customer
  belongs_to :state_province
  belongs_to :address_type
  belongs_to :usps_record_type
end

# == Schema Information
#
# Table name: customer_address
#
#  id                  :integer(10)     not null, primary key
#  customer_id         :integer(10)
#  address_type_id     :integer(10)
#  usps_record_type_id :integer(10)
#  address_line_1      :string(255)
#  address_line_2      :string(255)
#  address_line_3      :string(255)
#  address_line_4      :string(255)
#  address_line_5      :string(255)
#  city_name           :string(255)
#  state_province_id   :integer(10)
#  postal_code         :string(255)
#  county_code         :string(255)
#  country_id          :integer(10)
#  effective_date      :datetime        not null
#  zip_code            :integer(10)
#

