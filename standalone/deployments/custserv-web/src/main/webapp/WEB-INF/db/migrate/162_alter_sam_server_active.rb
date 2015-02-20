class AlterSamServerActive < ActiveRecord::Migration
  def self.up
    remove_column :sam_server, :active
    add_column :sam_server, :active, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :sam_server, :active
    add_column :sam_server, :active, :boolean, :default => true
  end
end
