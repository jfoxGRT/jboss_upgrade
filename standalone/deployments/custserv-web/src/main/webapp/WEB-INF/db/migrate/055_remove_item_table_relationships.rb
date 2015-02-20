class RemoveItemTableRelationships < ActiveRecord::Migration
  def self.up
    add_column :entitlement, :product_id, :integer, :references => :product, :null => true
    drop_table :product_version
  end

  def self.down
    remove_column :entitlement, :product_id
  end
end
