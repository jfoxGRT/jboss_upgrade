class CreateScheduledUpdate < ActiveRecord::Migration
  def self.up
    create_table :scheduled_update do |t|
      t.column "sam_customer_id",  :integer, :null => false, :references => :sam_customer
      t.column "sapling_id", :integer, :null => false, :references => :sapling
      t.column "community_id", :integer, :null => false, :references => :community
      t.column "version", :string, :null => false
      t.column "notes", :text
    end
  end

  def self.down
    drop_table :scheduled_update
  end
end
