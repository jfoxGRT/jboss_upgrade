class RoleGroup < ActiveRecord::Base
  set_table_name "role_group"
end

# == Schema Information
#
# Table name: role_group
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

