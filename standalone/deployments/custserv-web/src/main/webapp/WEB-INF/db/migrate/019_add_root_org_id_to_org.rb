class AddRootOrgIdToOrg < ActiveRecord::Migration
  def self.up
    add_column :org, :top_level_org_id, :integer, :references => "org"
  end

  def self.down
    remove_column :org, :top_level_org_id
  end
end
