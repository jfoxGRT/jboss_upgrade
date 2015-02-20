class DelivStatus < ActiveRecord::Base
  acts_as_cached
  set_table_name "deliv_status"
end

# == Schema Information
#
# Table name: deliv_status
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

