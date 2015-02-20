class AddressType < ActiveRecord::Base
  acts_as_cached
  set_table_name "address_type"
  
  @@MAILING_CODE = "05"
  
  def self.MAILING_CODE
    @@MAILING_CODE
  end
  
end

# == Schema Information
#
# Table name: address_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(255)
#

