class TelephoneType < ActiveRecord::Base
  acts_as_cached
  set_table_name "telephone_type"
  
  @@MAIN_CODE = "05"
  
  def self.MAIN_CODE
    @@MAIN_CODE
  end
  
end

# == Schema Information
#
# Table name: telephone_type
#
#  id                                :integer(10)     not null, primary key
#  code                              :string(255)
#  customer_classification_indicator :string(255)
#  description                       :string(255)
#  text                              :string(255)
#

