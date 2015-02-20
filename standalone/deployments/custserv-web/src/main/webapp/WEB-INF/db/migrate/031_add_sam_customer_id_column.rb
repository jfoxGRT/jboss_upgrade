class AddSamCustomerIdColumn < ActiveRecord::Migration
  def self.up
    add_column :users, :sam_customer_id, :integer, :null => true, :references => :sam_customer
  end

  def self.down
    remove_column :users, :sam_customer_id
  end
end
