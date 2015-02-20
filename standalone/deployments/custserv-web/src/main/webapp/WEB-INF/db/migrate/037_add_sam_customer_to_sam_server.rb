class AddSamCustomerToSamServer < ActiveRecord::Migration
  def self.up
    add_column :sam_server, :sam_customer_id, :integer, :null => false, :references => :sam_customer
  end

  def self.down
    remove_column :sam_server, :sam_customer_id
  end
end
