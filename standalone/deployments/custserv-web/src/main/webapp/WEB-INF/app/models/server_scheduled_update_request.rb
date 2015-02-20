class ServerScheduledUpdateRequest < ActiveRecord::Base
  set_table_name "server_scheduled_update_request"
  belongs_to :conversation_instance
  belongs_to :user
  belongs_to :sam_server
  belongs_to :sapling
  
  # Cancels 
  def cancel_request(user_id)
      self.status = 'x'
      self.updated_at = Time.now
      self.completed_at = Time.now
      self.success = 0
      
      conversation_instance = ConversationInstance.find(:all,
                                     :conditions => ["id = ?", self.conversation_instance_id])
        
        if( !conversation_instance.nil? )
          conversation_instance.each do |convo|
            convo.expire_requests(user_id)
            convo.save!
          end
        end
        
      self.save!
   end
end

# == Schema Information
#
# Table name: server_scheduled_update_request
#
#  id                               :integer(10)     not null, primary key
#  created_at                       :datetime
#  updated_at                       :datetime
#  success                          :boolean
#  schedule_at                      :datetime
#  completed_at                     :datetime
#  sam_server_id                    :integer(10)     not null
#  conversation_instance_id         :integer(10)
#  user_id                          :integer(10)
#  sapling_id                       :integer(10)
#  updates_completed_email_sent     :boolean         default(FALSE), not null
#

