class AddSeatBucket < ActiveRecord::Migration
  def self.up
    create_table "seat_bucket", :force => true do |t|
      t.column "sam_customer_id",        :integer, :null => false, :references => :sam_customer
      t.column "subcommunity_id",        :integer, :null => false, :references => :subcommunity
      t.column "sc_entitlement_type_id", :integer, :references => :sc_entitlement_type
      t.column "seat_count",             :integer, :default => 0
    end
    Seat.update_all("orig_seat_id = null")
    Seat.delete_all
    remove_column :seat, :entitlement_id    
    add_column    :seat, :seat_bucket_id, :integer, :null => false, :references => :seat_bucket
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
