class RemoveUnusedUsersColumns < ActiveRecord::Migration
  def self.up
    remove_column :users, :login
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
  end

  def self.down  
    add_column :users, :remember_token_expires_at, :datetime
    add_column :users, :remember_token, :string
    add_column :users, :login, :string
  end
end
