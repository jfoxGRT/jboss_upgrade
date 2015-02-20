class AddCustomerAddressIndex < ActiveRecord::Migration
  def self.up
    add_index :customer_address, [:customer_id, :address_type_id], :unique
  end

  def self.down  
    remove_index :users, :column => [:customer_id, :address_type_id]
  end
end
