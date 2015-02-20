class OrderType < ActiveRecord::Base
  acts_as_cached
  set_table_name "order_types"
end

# == Schema Information
#
# Table name: order_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

