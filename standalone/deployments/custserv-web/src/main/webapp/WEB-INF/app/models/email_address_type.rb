class EmailAddressType < ActiveRecord::Base
  acts_as_cached
  set_table_name "email_address_type"
end

# == Schema Information
#
# Table name: email_address_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#  text        :string(255)
#

