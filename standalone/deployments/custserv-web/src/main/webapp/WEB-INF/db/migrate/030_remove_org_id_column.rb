class RemoveOrgIdColumn < ActiveRecord::Migration
  def self.up
    remove_column :users, :org_id
  end

  def self.down
    add_column :users, :org_id, :integer, :references => :org
  end
end
