class AddAuditAgentEvent < ActiveRecord::Migration
  def self.up
    create_table :audit_agent_event do |t|
      t.column :timestamp, :datetime, :null => false
      t.column :event_type, :string, :null => false
      t.column :agent_id, :integer, :null => true, :references => nil
      t.column :agent_ip, :string, :null => true
      t.column :token_direction, :string, :null => false
      t.column :token_machine_guid, :string, :null => true
      t.column :token_agent_cookie, :string, :null => true
      t.column :token_plugin_id, :string, :null => true, :references => nil
      t.column :token_command_id, :string, :null => true, :references => nil
      t.column :token_success, :boolean, :null => true
    end
    create_table :audit_agent_event_param do |t|
      t.column :audit_agent_event_id, :integer, :null => false, :references => :audit_agent_event
      t.column :name, :string, :null => true
      t.column :value, :text, :null => true
    end
    create_table :audit_agent_event_error do |t|
      t.column :audit_agent_event_id, :integer, :null => false, :references => :audit_agent_event
      t.column :name, :string, :null => true
      t.column :value, :text, :null => true
    end
  end

  def self.down
    drop_table :audit_agent_event_error
    drop_table :audit_agent_event_param
    drop_table :audit_agent_event
  end
end
