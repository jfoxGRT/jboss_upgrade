class AddUsersRegisteredAt < ActiveRecord::Migration
  def self.up
    add_column :users, :registered_at, :datetime, :null => true
  end

  def self.down
    remove_column :users, :registered_at
  end
end
