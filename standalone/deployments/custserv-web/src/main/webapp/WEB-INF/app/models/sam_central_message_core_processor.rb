class SamCentralMessageCoreProcessor < ActiveRecord::Base
  set_table_name "sam_central_message_core_processor"
  
  # should match the queueName Spring property configured for the CheckQueueJobBean in Java application
  @@QUEUE_NAME = 'Core Processor Queue'
  
  def self.QUEUE_NAME
    @@QUEUE_NAME
  end
  
end

# == Schema Information
#
# Table name: sam_central_message_core_processor
#
#  id         :integer(10)     not null, primary key
#  message    :text            not null
#  created_at :datetime        not null
#  priority   :integer(10)     not null
#

