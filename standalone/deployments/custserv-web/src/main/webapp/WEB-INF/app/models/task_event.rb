class TaskEvent < ActiveRecord::Base
  belongs_to :task
  belongs_to :source_user, :foreign_key => "source_user_id", :class_name => "User"
  belongs_to :target_user, :foreign_key => "target_user_id", :class_name => "User"
  belongs_to :sam_customer, :foreign_key => "sam_customer_id", :class_name => "SamCustomer"
  
  @@ASSIGN = 'a'
  @@UNASSIGN = 'u'
  @@CLOSE = 'c'
  @@REOPEN = 'o'
  @@MAKE_OBSOLETE = 'z'
  
  def self.ASSIGN
    @@ASSIGN
  end
  
  def self.UNASSIGN
    @@UNASSIGN
  end
  
  def self.CLOSE
    @@CLOSE
  end
  
  def self.REOPEN
    @@REOPEN
  end
  
  def self.MAKE_OBSOLETE
    @@MAKE_OBSOLETE
  end
  
  
end

# == Schema Information
#
# Table name: task_events
#
#  id              :integer(10)     not null, primary key
#  task_id         :integer(10)     not null
#  source_user_id  :integer(10)
#  target_user_id  :integer(10)
#  created_at      :datetime        not null
#  action          :string(1)       not null
#  comment         :text
#  sam_customer_id :integer(10)
#

