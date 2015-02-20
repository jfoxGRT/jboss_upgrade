class AddAgentIdToAlertInstance < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :agent_id, :integer, :null => true, :references => nil
  end

  def self.down
    remove_column :alert_instance, :agent_id
  end
end