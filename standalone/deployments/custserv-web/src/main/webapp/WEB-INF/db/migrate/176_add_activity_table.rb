class AddActivityTable < ActiveRecord::Migration
  def self.up
    create_table(:seat_activity) do |t|
      t.column :seat_pool_id, :integer, :references => :seat_pool, :null => false
      t.column :current_count, :integer, :null => false
      t.column :delta, :integer, :null => false
      t.column :created_at, :datetime
      t.column :conversation_instance_id, :integer, :references => :conversation_instance
      t.column :done, :boolean, :null => false, :default => false
      t.column :user_id, :integer, :references => :users
    end
  end

  def self.down
    drop_table(:seat_activity)
  end
end
