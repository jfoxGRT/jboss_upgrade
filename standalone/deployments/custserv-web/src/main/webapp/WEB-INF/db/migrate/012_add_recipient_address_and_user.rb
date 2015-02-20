class AddRecipientAddressAndUser < ActiveRecord::Migration
  def self.up
    add_column :email_message, :recipient_address, :string, :null => false
    add_column :email_message, :user_id, :integer, :null => false, :references => :users
  end

  def self.down
    remove_column :email_message, :recipient_address
  end
end
