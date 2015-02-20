class ModifyUsersType < ActiveRecord::Migration
  def self.up
     remove_column :users, :user_type
     add_column :users, :user_type, :string, :limit => 1, :null => false, :default => 'c'
  end

  def self.down
    remove_column :users, :user_type
    add_column :users, :user_type, :string, :limit => 1, :null => true
  end
end
