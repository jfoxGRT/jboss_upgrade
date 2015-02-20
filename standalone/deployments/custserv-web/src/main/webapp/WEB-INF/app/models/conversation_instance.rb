class ConversationInstance < ActiveRecord::Base
  set_table_name "conversation_instance"
  belongs_to :agent
  belongs_to :result_type
  has_many :conversation_instance_variables
  has_one :conversation_current_state
  has_many :conversation_state_instances
  has_one :retry_child, :class_name => "ConversationInstance", :foreign_key => "retry_parent_conversation_instance_id"
  has_one :seat_activity
  belongs_to :async_activity
  belongs_to :conv_export_sub_batch
  
  # Expire report requests
  def expire_requests(user_id)

  	self.result_type_id = 4
  	self.updated_at = Time.now
  	self.completed = Time.now
  	self.result_msg = "Expired by user " + user_id.to_s
  	
  end
end

# == Schema Information
#
# Table name: conversation_instance
#
#  id                                      :integer(10)     not null, primary key
#  adapter_identifier                      :string(255)
#  conversation_identifier                 :string(255)
#  agent_id                                :integer(10)     not null
#  created_at                              :datetime        not null
#  updated_at                              :datetime        not null
#  started                                 :datetime
#  completed                               :datetime
#  result_type_id                          :integer(10)     not null
#  result_msg                              :string(2048)
#  retry_timeout_end                       :datetime
#  retry_parent_conversation_instance_id   :integer(10)
#  retry_original_conversation_instance_id :integer(10)
#  priority                                :integer(10)     default(0)
#  embargo_until                           :datetime
#  express_conversation                    :boolean         default(FALSE), not null
#  expiration_date                         :datetime
#  ignore_conversation                     :boolean
#  async_activity_id                       :integer(10)
#  result_code                             :integer(10)
#  conv_export_sub_batch_id                :integer(10)
#

