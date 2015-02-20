class AddColumnLastLocalIpToAgent < ActiveRecord::Migration
  def self.up
    add_column :agent, :last_local_ip, :string
  end

  def self.down
    remove_column :agent, :last_local_ip
  end
end
