class AddAssignedColumn < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :date_assigned, :datetime, :null => true
    add_column :alert_instance, :date_closed, :datetime, :null => true
    add_column :alert_instance, :assigning_user_id, :integer, :null => true, :references => :users
  end

  def self.down
    remove_column :alert_instance, :date_assigned
    remove_column :alert_instance, :date_closed
    remove_column :alert_instance, :assigning_user_id
  end
end
