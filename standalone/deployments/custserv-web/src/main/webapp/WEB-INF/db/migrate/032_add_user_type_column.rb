class AddUserTypeColumn < ActiveRecord::Migration
  def self.up
    add_column :users, :user_type, :string, :limit => 1, :null => true
  end

  def self.down
    remove_column :users, :user_type
  end
end
