class AddAgentPollOverride < ActiveRecord::Migration
  def self.up
    add_column :agent, :poll_override, :integer, :null => true
    add_column :agent, :poll_override_expires_at, :datetime, :null => true
  end

  def self.down
    remove_column :agent, :poll_override_expired_at
    remove_column :agent, :poll_override
  end
end
