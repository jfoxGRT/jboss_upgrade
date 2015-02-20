class DropSomeTriggers < ActiveRecord::Migration
  def self.up
    execute "DROP TRIGGER IF EXISTS seat_summary_update_trigger"
    execute "DROP TRIGGER IF EXISTS seat_summary_insert_trigger"
    execute "DROP TRIGGER IF EXISTS seat_summary_delete_trigger"
  end

  def self.down  
  end
end
