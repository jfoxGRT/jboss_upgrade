class RenameRootOrgIdColumn < ActiveRecord::Migration
  def self.up
    rename_column :alert_instance, :root_org_id, :org1_id
    rename_column :alert_instance, :org_id, :org2_id
  end

  def self.down
    rename_column :alert_instance, :org1_id, :root_org_id
    rename_column :alert_instance, :org2_id, :org_id
  end
end
