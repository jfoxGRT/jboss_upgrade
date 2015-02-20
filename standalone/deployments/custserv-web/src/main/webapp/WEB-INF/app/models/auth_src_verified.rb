class AuthSrcVerified < ActiveRecord::Base
  acts_as_cached
  set_table_name "auth_src_verified"
end

# == Schema Information
#
# Table name: auth_src_verified
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#  text        :string(255)
#

