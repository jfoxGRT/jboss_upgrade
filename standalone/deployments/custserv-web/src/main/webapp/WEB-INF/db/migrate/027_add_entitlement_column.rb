class AddEntitlementColumn < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :entitlement_id, :integer, :null => true, :references => :entitlement
  end

  def self.down
    remove_column :alert_instance, :entitlement_id
  end
end
