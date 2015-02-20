class RelationshipType < ActiveRecord::Base
  acts_as_cached
  set_table_name "relationship_type"
  
  @@ORG_TO_ORG_CODE = "03"
  
  def self.ORG_TO_ORG_CODE
    @@ORG_TO_ORG_CODE
  end
  
end

# == Schema Information
#
# Table name: relationship_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#  text        :string(255)
#

