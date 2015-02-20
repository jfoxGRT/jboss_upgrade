class CreateServerScheduledUpdate < ActiveRecord::Migration
  def self.up
    create_table :server_scheduled_update do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime
      t.column "scheduled_at", :datetime
      t.column "completed_at", :datetime
      t.column "scheduled_update_id", :integer, :null => false, :references => :scheduled_update
      t.column "sam_server_id", :integer, :null => false, :references => :sam_server
    end
  end

  def self.down
    drop_table :server_scheduled_update
  end
end
