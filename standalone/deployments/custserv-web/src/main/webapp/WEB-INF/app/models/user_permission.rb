class UserPermission < ActiveRecord::Base
  set_table_name "user_permission"
  belongs_to :permission
  belongs_to :user
end

# == Schema Information
#
# Table name: user_permission
#
#  id            :integer(10)     not null, primary key
#  user_id       :integer(10)     not null
#  permission_id :integer(10)     not null
#

