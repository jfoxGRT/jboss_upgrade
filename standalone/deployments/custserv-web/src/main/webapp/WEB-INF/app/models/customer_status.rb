class CustomerStatus < ActiveRecord::Base
  set_table_name "customer_status"
  
  @@OPEN_CODE = "01"
  @@CLOSED_CODE = "02"
  @@TERMINATED_CODE = "03"
  
  def self.OPEN_CODE
    @@OPEN_CODE
  end
  
  def self.CLOSED_CODE
    @@CLOSED_CODE
  end
  
  def self.TERMINATED_CODE
    @@TERMINATED_CODE
  end
  
end

# == Schema Information
#
# Table name: customer_status
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

