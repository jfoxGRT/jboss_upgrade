class CustomerGroup < ActiveRecord::Base
  set_table_name "customer_group"
  
  @@DISTRICT_CODE = "D"
  @@SCHOOL_CODE = "S"
  @@OTHER_SCHOOLS_CODE = "OS"
  
  def self.DISTRICT_CODE
    @@DISTRICT_CODE
  end
  
  def self.SCHOOL_CODE
    @@SCHOOL_CODE
  end
  
  def self.OTHER_SCHOOLS_CODE
    @@OTHER_SCHOOLS_CODE
  end
  
end

# == Schema Information
#
# Table name: customer_group
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

