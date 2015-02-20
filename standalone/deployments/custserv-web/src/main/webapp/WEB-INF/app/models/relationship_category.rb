class RelationshipCategory < ActiveRecord::Base
  set_table_name "relationship_category"
  
  @@SUP2SUB_CODE = "01"
  
  def self.SUP2SUB_CODE
    @@SUP2SUB_CODE
  end
  
  
end

# == Schema Information
#
# Table name: relationship_category
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#  text        :string(255)
#

