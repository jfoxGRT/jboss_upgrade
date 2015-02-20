class FullyActivatedSubcommunity < ActiveRecord::Base
  set_table_name "fully_activated_subcommunities"
  belongs_to :sam_customer
  belongs_to :subcommunity
  belongs_to :user  
end

# == Schema Information
#
# Table name: fully_activated_subcommunities
#
#  id              :integer(10)     not null, primary key
#  sam_customer_id :integer(10)     not null
#  subcommunity_id :integer(10)     not null
#  user_id         :integer(10)
#  created_at      :datetime
#  updated_at      :datetime
#  status          :boolean         default(TRUE), not null
#

