class ConversationInstanceVariable < ActiveRecord::Base
  set_table_name "conversation_instance_variable"
  belongs_to :conversation_instance
end

# == Schema Information
#
# Table name: conversation_instance_variable
#
#  id                       :integer(10)     not null, primary key
#  conversation_instance_id :integer(10)
#  name                     :string(255)
#  value                    :text
#

