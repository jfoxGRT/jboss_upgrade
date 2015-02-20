class ProcessMessage < ActiveRecord::Base
  set_table_name "process_messages"
  has_many :process_message_responses
  belongs_to :samc_process
end

# == Schema Information
#
# Table name: process_messages
#
#  id            :integer(10)     not null, primary key
#  message_token :string(255)     not null
#  created_at    :datetime        not null
#  process_id    :integer(10)     not null
#  message_code  :string(10)      not null
#

