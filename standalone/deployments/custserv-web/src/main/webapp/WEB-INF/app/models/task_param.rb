class TaskParam < ActiveRecord::Base
  belongs_to :task
  
  @@UO_EXCEPTION_TYPE = 'exceptionType'

  def self.UO_EXCEPTION_TYPE
    @@UO_EXCEPTION_TYPE
  end
  
end
# == Schema Information
#
# Table name: task_params
#
#  id      :integer(10)     not null, primary key
#  task_id :integer(10)     not null
#  name    :string(255)
#  value   :string(255)
#

