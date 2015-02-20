class AddAllocationCompliance < ActiveRecord::Migration
  def self.up
    create_table :allocation_compliance do |t|
      t.column :sam_server_id, :integer, :null => false, :references => :sam_server
      t.column :subcommunity_id, :integer, :null => false, :references => :subcommunity
      t.column :assignable, :integer, :null => false
      t.column :active, :integer, :null => false
      t.column :check_date, :datetime, :null => false
      t.column :compliant, :boolean, :null => false
    end
  end

  def self.down
    drop_table :allocation_compliance
  end
end
