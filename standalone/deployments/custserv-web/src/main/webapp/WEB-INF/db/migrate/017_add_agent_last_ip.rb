class AddAgentLastIp < ActiveRecord::Migration
  def self.up
    add_column :agent, :last_ip, :string, :null => true
  end

  def self.down
  	remove_column :agent, :last_ip
  end
end
