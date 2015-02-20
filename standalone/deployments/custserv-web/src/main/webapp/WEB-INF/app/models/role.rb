class Role < ActiveRecord::Base
  set_table_name "role"
end

# == Schema Information
#
# Table name: role
#
#  id   :integer(10)     not null, primary key
#  code :string(255)     not null
#  name :string(255)     not null
#

