class AddSamCustomerIdToEntitlement < ActiveRecord::Migration
  def self.up
    add_column :entitlement, :sam_customer_id, :integer, :null => true, :references => :sam_customer
  end

  def self.down
    remove_column :entitlement, :sam_customer_id
  end
end
