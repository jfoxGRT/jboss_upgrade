class AddSamServerAggServer < ActiveRecord::Migration
  def self.up
    add_column :sam_server, :agg_server, :boolean, :null => true
  end

  def self.down
    remove_column :sam_server, :agg_server
  end
end
