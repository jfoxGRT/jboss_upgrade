class AddSamCustomerTimeZone < ActiveRecord::Migration
  def self.up
    add_column :sam_customer, :sam_time_zone_id, :integer, :null => true, :references => :sam_time_zone
  end
  
  def self.down
    remove_column :sam_customer, :sam_time_zone_id
  end
end
