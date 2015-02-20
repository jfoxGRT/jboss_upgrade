class AddUsersConstraints < ActiveRecord::Migration
  def self.up
    add_index :users, :email, :unique
    add_index :users, :token, :unique
  end

  def self.down  
    remove_index :users, :token
    remove_index :users, :email
  end
end
