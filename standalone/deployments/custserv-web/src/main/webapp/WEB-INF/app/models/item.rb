class Item < ActiveRecord::Base
  acts_as_cached
  set_table_name "item"
  has_many   :entitlements
  
end

# == Schema Information
#
# Table name: item
#
#  id          :integer(10)     not null, primary key
#  item_num    :string(255)     not null
#  description :string(255)
#  licenses    :integer(10)     not null
#  item_type   :string(255)
#

