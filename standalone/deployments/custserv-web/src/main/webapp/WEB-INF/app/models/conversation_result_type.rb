class ConversationResultType < ActiveRecord::Base
  acts_as_cached
  set_table_name "conversation_result_type"
end

# == Schema Information
#
# Table name: conversation_result_type
#
#  id   :integer(10)     not null, primary key
#  code :string(255)
#  name :string(255)
#

