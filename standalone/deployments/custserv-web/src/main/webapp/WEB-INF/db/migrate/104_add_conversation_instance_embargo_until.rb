class AddConversationInstanceEmbargoUntil < ActiveRecord::Migration
  def self.up
    add_column :conversation_instance, :embargo_until, :datetime, :null=> true
  end

  def self.down
    remove_column :conversation_instance, :embargo_until
  end
end
