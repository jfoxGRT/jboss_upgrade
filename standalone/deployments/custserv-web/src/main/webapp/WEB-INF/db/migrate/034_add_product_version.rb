class AddProductVersion < ActiveRecord::Migration
  def self.up
    add_column :entitlement, :marketing_version, :string, :null => true
  end

  def self.down
    remove_column :entitlement, :marketing_version
  end
end
