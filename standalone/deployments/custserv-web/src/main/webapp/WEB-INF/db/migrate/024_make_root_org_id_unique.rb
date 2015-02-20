class MakeRootOrgIdUnique < ActiveRecord::Migration
  def self.up
    add_index(:sam_customer, :root_org_id, :unique => true)
  end

  def self.down
    remove_index(:sam_customer, :root_org_id)
  end
end
