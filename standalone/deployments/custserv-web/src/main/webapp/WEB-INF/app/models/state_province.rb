class StateProvince < ActiveRecord::Base
  set_table_name "state_province"
  belongs_to :country  
end

# == Schema Information
#
# Table name: state_province
#
#  id                 :integer(10)     not null, primary key
#  code               :string(3)
#  country_id         :integer(10)
#  name               :string(75)
#  sam_customer_count :integer(10)     default(0), not null
#  display_name       :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

