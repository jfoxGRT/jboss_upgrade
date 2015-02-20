class Community < ActiveRecord::Base
  acts_as_cached
  set_table_name "community"
end

# == Schema Information
#
# Table name: community
#
#  id   :integer(10)     not null, primary key
#  code :string(255)
#  name :string(255)
#

