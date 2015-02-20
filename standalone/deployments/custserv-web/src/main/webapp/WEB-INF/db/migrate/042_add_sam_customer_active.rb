class AddSamCustomerActive < ActiveRecord::Migration
  def self.up
    add_column :sam_customer, :active, :boolean, :default => true
  end

  def self.down
    remove_column :sam_customer, :active
  end
end
