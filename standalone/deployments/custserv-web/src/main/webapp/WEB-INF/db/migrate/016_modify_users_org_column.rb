class ModifyUsersOrgColumn < ActiveRecord::Migration
  def self.up
    remove_column :users, :org_id
    add_column :users, :org_id, :integer, :null => true, :references => nil
    add_index "users", ["org_id"], :name => "org_id"
    add_foreign_key "users", ["org_id"], "org", ["id"]
  end

  def self.down
  end
end
