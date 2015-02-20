class AddToken2ColumnToAi < ActiveRecord::Migration
  def self.up
    add_column :alert_instance, :token_2, :string, :null => true
  end

  def self.down
    remove_column :alert_instance, :token_2
  end
end
