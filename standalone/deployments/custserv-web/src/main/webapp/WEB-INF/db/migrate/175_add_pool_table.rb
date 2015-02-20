class AddPoolTable < ActiveRecord::Migration
  def self.up
    create_table(:seat_pool) do |t|
      t.column :sam_customer_id, :integer, :references => :sam_customer, :null => false
      t.column :subcommunity_id, :integer, :references => :subcommunity, :null => false
      t.column :sam_server_id, :integer, :references => :sam_server
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :seat_count, :integer, :null => false
    end
    add_index(:seat_pool, :sam_customer_id)
    add_index(:seat_pool, [:sam_customer_id, :subcommunity_id])
  end

  def self.down
    drop_table(:seat_pool)
  end
end
