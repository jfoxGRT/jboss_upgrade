class AddSamCustomerCount < ActiveRecord::Migration
  def self.up
    add_column :state_province, :sam_customer_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :state_province, :sam_customer_count
  end
end
