class AddTokenColumnToAi < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :token, :string, :null => true
  end

  def self.down
    remove_column :alert_instance, :token
  end
end
