class RenameAgentCommunity < ActiveRecord::Migration
  def self.up
    rename_table "agent_community", "agent_component"
  end

  def self.down
    rename_table "agent_component", "agent_community"
  end
end
