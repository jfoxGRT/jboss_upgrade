class AddEntitlementAuditTable < ActiveRecord::Migration
  def self.up
    create_table(:entitlement_audit) do |t|
      t.column :entitlement_id, :integer, :null => false, :references => :entitlement
      t.column :annotation, :text, :null => false
      t.column :initial_conversion, :boolean, :null => false, :default => false
      t.column :user_id, :integer, :null => false, :references => :users
    end
  end

  def self.down
    drop_table(:entitlement_audit)
  end
end
