class AddSamCustomerToAlert < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :sam_customer_id, :integer, :null => true, :references => :sam_customer
  end

  def self.down
    remove_column :alert_instance, :sam_customer_id
  end
end
