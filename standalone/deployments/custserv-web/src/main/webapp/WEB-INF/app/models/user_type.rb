class UserType < ActiveRecord::Base
  acts_as_cached
  set_table_name "user_types"
end

# == Schema Information
#
# Table name: user_types
#
#  id         :integer(10)     not null, primary key
#  code       :string(1)       not null
#  short_desc :string(255)     not null
#  long_desc  :text            not null
#

