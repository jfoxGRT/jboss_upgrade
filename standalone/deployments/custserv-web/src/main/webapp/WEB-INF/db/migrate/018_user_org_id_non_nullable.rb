class UserOrgIdNonNullable < ActiveRecord::Migration
  def self.up
    change_column :users, :org_id, :integer, :null => false, :references => "org"
    change_column :users, :first_name, :string, :null => false
    change_column :users, :last_name, :string, :null => false
    change_column :users, :email, :string, :null => false
    change_column :users, :login, :string, :null => false
  end

  def self.down
    change_column :users, :org_id, :integer, :null => true, :references => "org"
    change_column :users, :first_name, :string, :null => true
    change_column :users, :last_name, :string, :null => true
    change_column :users, :email, :string, :null => true
    change_column :users, :login, :string, :null => true  
  end
end
