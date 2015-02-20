class AddRejectedEntitlementTab < ActiveRecord::Migration
  def self.up
    create_table :rejected_entitlement do |t|
      t.column :po_num, :string
      t.column :license_count, :integer
      t.column :license_portability_code, :string
      t.column :license_portability_desc, :string
      t.column :ordered, :datetime, :null => false
      t.column :shipped, :datetime
      t.column :email_address, :string
      t.column :first_name, :string
      t.column :last_name, :string
      t.column :entitlement_type_code, :string
      t.column :entitlement_type_desc, :string
      t.column :license_duration_code, :string
      t.column :license_duration_desc, :string
      t.column :order_num, :string, :null => false
      t.column :originating_order_num, :string
      t.column :shipment_num, :string
      t.column :invoice_num, :string
      t.column :master_order_num, :string
      t.column :license_count_type, :string
      t.column :item_quantity, :integer
      t.column :contact_ucn, :string
      t.column :subscription_start, :datetime
      t.column :subscription_end, :datetime
      t.column :grace_period_code, :string
      t.column :grace_period_desc, :string
      t.column :item_number, :string, :null => false
      t.column :tms_entitlementid, :string, :null => false
      t.column :marketing_version, :string
      t.column :bill_to_ucn, :string
      t.column :ship_to_ucn, :string
    end
  end

  def self.down
    drop_table :rejected_entitlement
  end
end
