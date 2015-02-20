class AddEsbMessageCorrelationIndex < ActiveRecord::Migration
  def self.up
    add_index :esb_message, [:correlation_id]
  end

  def self.down  
    remove_index :esb_message, :column => [:correlation_id]
  end
end
