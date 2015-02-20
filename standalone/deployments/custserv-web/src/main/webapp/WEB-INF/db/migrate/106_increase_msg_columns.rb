class IncreaseMsgColumns < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE alert_instance MODIFY COLUMN message varchar(4096)"    
    execute "ALTER TABLE conversation_command_property MODIFY COLUMN value varchar(4096)"    
  end

  def self.down
  end
end
