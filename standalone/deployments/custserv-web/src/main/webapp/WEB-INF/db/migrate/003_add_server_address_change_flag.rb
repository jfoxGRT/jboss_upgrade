class AddServerAddressChangeFlag < ActiveRecord::Migration
  def self.up
    add_column :sam_server_address, :change_indicator, :string, :limit => 7
  end

  def self.down
    remove_column :sam_server_address, :change_indicator
  end
end
