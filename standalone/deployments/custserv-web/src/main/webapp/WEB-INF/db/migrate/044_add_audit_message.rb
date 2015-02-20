class AddAuditMessage < ActiveRecord::Migration
  def self.up
    create_table :audit_message do |t|
      t.column :timestamp, :datetime, :null => false
      t.column :class, :string, :null => false
      t.column :event_type, :string, :null => true
      t.column :token, :string, :null => true
    end
    create_table :audit_message_prop do |t|
      t.column :audit_message_id, :integer, :null => false, :references => :audit_message
      t.column :name, :string, :null => true
      t.column :value, :string, :null => true
    end
  end

  def self.down
    drop_table :audit_message_prop
    drop_table :audit_message
  end
end
