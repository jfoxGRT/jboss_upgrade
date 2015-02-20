class EntitlementTableConstraints < ActiveRecord::Migration
  def self.up
    change_column :entitlement, :ordered, :datetime, :null => false
    change_column :entitlement, :order_num, :string, :null => false
    change_column :entitlement, :invoice_num, :string, :null => false
  end

  def self.down
    change_column :entitlement, :ordered, :datetime, :null => true
    change_column :entitlement, :order_num, :string, :null => true
    change_column :entitlement, :invoice_num, :string, :null => true
  end
end
