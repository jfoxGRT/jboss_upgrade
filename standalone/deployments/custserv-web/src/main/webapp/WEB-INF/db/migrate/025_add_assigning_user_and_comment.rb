class AddAssigningUserAndComment < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :assigned_user_id, :integer, :null => true, :references => :users
    add_column :alert_instance, :comment, :text
  end

  def self.down
    remove_column :alert_instance, :assigned_user_id
    remove_column :alert_instance, :comment
  end
end
