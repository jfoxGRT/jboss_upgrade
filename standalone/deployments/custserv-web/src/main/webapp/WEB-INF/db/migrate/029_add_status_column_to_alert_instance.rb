class AddStatusColumnToAlertInstance < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :status, :string, :null => true
  end

  def self.down
    remove_column :alert_instance, :status
  end
end
