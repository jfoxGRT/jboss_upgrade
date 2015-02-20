class ConversationCommandError < ActiveRecord::Base
  set_table_name "conversation_command_error"
  belongs_to :conversation_command
end

# == Schema Information
#
# Table name: conversation_command_error
#
#  id                      :integer(10)     not null, primary key
#  name                    :string(255)     not null
#  value                   :text
#  conversation_command_id :integer(10)     not null
#

