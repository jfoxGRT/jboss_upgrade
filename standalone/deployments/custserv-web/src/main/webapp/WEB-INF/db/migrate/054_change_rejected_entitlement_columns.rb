class ChangeRejectedEntitlementColumns < ActiveRecord::Migration
  def self.up
    change_column :rejected_entitlement, :ordered, :string, :null => true
    change_column :rejected_entitlement, :order_num, :string, :null => true
    change_column :rejected_entitlement, :item_number, :string, :null => true
    change_column :rejected_entitlement, :license_count, :string
    change_column :rejected_entitlement, :shipped, :string
    change_column :rejected_entitlement, :item_quantity, :string
    change_column :rejected_entitlement, :subscription_start, :string
    change_column :rejected_entitlement, :subscription_end, :string
    change_column :rejected_entitlement, :tms_entitlementid, :string, :null => true
  end

  def self.down
    change_column :rejected_entitlement, :ordered, :datetime, :null => false
    change_column :rejected_entitlement, :order_num, :string, :null => false
    change_column :rejected_entitlement, :item_number, :string, :null => false
    change_column :rejected_entitlement, :license_count, :integer
    change_column :rejected_entitlement, :shipped, :datetime
    change_column :rejected_entitlement, :item_quantity, :integer
    change_column :rejected_entitlement, :subscription_start, :datetime
    change_column :rejected_entitlement, :subscription_end, :datetime
    change_column :rejected_entitlement, :tms_entitlementid, :string, :null => false
  end
end
