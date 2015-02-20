class AddSamServerActive < ActiveRecord::Migration
  def self.up
    add_column :sam_server, :active, :boolean, :default => true
  end

  def self.down
    remove_column :sam_server, :active
  end
end
