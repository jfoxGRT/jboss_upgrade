class RemoveRoleStuff < ActiveRecord::Migration
  def self.up
    remove_column :alert, :target_role_id
    remove_column :permission, :role_id
  end

  def self.down
    add_column :alert, :target_role_id, :integer, :references => :role
    add_column :permission, :role_id, :integer, :references => :role
  end
end
