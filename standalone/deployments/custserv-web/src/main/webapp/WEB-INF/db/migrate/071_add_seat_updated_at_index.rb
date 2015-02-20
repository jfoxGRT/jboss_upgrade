class AddSeatUpdatedAtIndex < ActiveRecord::Migration
  def self.up
    add_index :seat, [:updated_at]
## decided to add these when needed in a later migration
##    add_index :seat_summary_event_runner, [:start_time]
##    add_index :seat_summary_event_runner, [:end_time]
  end

  def self.down
    remove_index :seat, :column => [:updated_at]
##    remove_index :seat_summary_event_runner, :column => [:start_time]
##    remove_index :seat_summary_event_runner, :column => [:end_time]
    
  end
end
