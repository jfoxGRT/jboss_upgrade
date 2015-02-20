class TopLevelOrg < ActiveRecord::Base
  set_table_name "top_level_org"
  belongs_to :org, :foreign_key => "org_id", :class_name => "Org"
  belongs_to :top_level_org, :foreign_key => "top_level_org_id", :class_name => "Org"
  
  @@ORG_HIERARCHY_POSITIONS = [["All Organizations", "AO"], ["Top-Level Organizations", "TLO"]]
  
  def self.ORG_HIERARCHY_POSITIONS
    @@ORG_HIERARCHY_POSITIONS
  end
  
end

# == Schema Information
#
# Table name: top_level_org
#
#  id               :integer(10)     not null, primary key
#  org_id           :integer(10)     not null
#  top_level_org_id :integer(10)
#

