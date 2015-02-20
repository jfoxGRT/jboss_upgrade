class AddSamCustomerFake < ActiveRecord::Migration
  def self.up
    add_column :sam_customer, :fake, :boolean, :default => false
  end

  def self.down
    remove_column :sam_customer, :fake
  end
end
