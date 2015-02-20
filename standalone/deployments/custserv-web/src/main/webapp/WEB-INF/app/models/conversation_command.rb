class ConversationCommand < ActiveRecord::Base
  set_table_name "conversation_command"
  belongs_to :conversation_state_instance
  has_many :conversation_command_properties
  has_many :conversation_command_error
end

# == Schema Information
#
# Table name: conversation_command
#
#  id                             :integer(10)     not null, primary key
#  command_id                     :string(255)     not null
#  plugin_id                      :string(255)     not null
#  conversation_state_instance_id :integer(10)     not null
#  success                        :integer(10)
#

