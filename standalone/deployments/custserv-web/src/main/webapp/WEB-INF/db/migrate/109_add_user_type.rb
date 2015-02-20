class AddUserType < ActiveRecord::Migration
  def self.up
    add_column :permission, :user_type, :string, :limit => 1, :default => 'c', :null => false
  end

  def self.down
    remove_column :permission, :user_type
  end
end
