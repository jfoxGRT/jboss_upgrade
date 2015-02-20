class AddOrgIdColumn < ActiveRecord::Migration
  def self.up
    add_column :entitlement_org, :org_id, :integer, :null => false, :references => :org
  end

  def self.down
    remove_column :entitlement_org, :org_id
  end
end
