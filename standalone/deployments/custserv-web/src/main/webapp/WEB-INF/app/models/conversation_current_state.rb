class ConversationCurrentState < ActiveRecord::Base
  set_table_name "conversation_current_state"
  belongs_to :conversation_instance
  belongs_to :conversation_state_instance
end

# == Schema Information
#
# Table name: conversation_current_state
#
#  id                             :integer(10)     not null, primary key
#  conversation_instance_id       :integer(10)
#  conversation_state_instance_id :integer(10)
#

