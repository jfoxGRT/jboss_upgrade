class AddAlertLongMessage < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :long_message, :text
  end

  def self.down
    remove_column :alert_instance, :long_message
  end
end
