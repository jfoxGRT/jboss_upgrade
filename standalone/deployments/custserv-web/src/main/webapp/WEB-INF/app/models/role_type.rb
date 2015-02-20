class RoleType < ActiveRecord::Base
  acts_as_cached
  set_table_name "role_type"
end

# == Schema Information
#
# Table name: role_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(4)
#  description :string(75)
#

