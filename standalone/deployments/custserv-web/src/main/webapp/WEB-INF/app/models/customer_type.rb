class CustomerType < ActiveRecord::Base
  acts_as_cached
  set_table_name "customer_type"
  
  @@LOCAL_UNIFIED_DISTRICT_CODE = "SL"
  
  @@ELEMENTARY_SCHOOL_THROUGH_GRADE_7 = "6E"
  
  @@INDIVIDUAL_CODE = "IND"
  
  def self.LOCAL_UNIFIED_DISTRICT_CODE
    @@LOCAL_UNIFIED_DISTRICT_CODE
  end
  
  def self.INDIVIDUAL_CODE
    @@INDIVIDUAL_CODE
  end
  
  def self.ELEMENTARY_SCHOOL_THROUGH_GRADE_7
    @@ELEMENTARY_SCHOOL_THROUGH_GRADE_7
  end
  
  
end

# == Schema Information
#
# Table name: customer_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(255)
#

