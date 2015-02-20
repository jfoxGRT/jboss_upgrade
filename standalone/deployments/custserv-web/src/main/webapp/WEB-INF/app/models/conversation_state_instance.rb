class ConversationStateInstance < ActiveRecord::Base
  set_table_name "conversation_state_instance"
  belongs_to :conversation_instance
  has_one :conversation_command
end

# == Schema Information
#
# Table name: conversation_state_instance
#
#  id                       :integer(10)     not null, primary key
#  conversation_instance_id :integer(10)
#  state_identifier         :string(255)
#  created_at               :datetime        not null
#  entered                  :datetime
#  exited                   :datetime
#

