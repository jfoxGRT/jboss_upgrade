class RemoveRootOrgColumnReferences < ActiveRecord::Migration
  def self.up
    remove_column :sam_server, :root_org_id
    remove_column :entitlement, :root_org_id
  end

  def self.down
  end
end
