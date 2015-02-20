class CreateBlackoutFilter < ActiveRecord::Migration
  def self.up
    create_table :blackout_filter do |t|
      t.column "sam_customer_id",  :integer, :null => false, :references => :sam_customer
      t.column "start_hour", :integer
      t.column "end_hour", :integer
      t.column "level", :string, :null => false
    end
  end

  def self.down
    drop_table :blackout_filter
  end
end
