class TaskType < ActiveRecord::Base
  set_table_name "task_types"
  
  @@UNASSIGNED_ENTITLEMENT_CODE = "UE"
  @@SUPER_ADMIN_REQUEST_CODE = "NSA"
  @@SC_LICENSING_ACTIVATION_CODE = "SCLA"
  @@LICENSE_COUNT_DISCREPANCY_CODE = "LCD"
  @@LICENSE_COUNT_INTEGRITY_PROBLEM_CODE = "LCIP"
  @@PENDING_LICENSE_COUNT_CHANGE_CODE = "PLCC"
  
  @@PENDING_ENTITLEMENT_CODE = "UE"
  
  def self.UNASSIGNED_ENTITLEMENT_CODE
    @@UNASSIGNED_ENTITLEMENT_CODE
  end
  
  def self.SUPER_ADMIN_REQUEST_CODE
    @@SUPER_ADMIN_REQUEST_CODE
  end
  
  def self.PENDING_ENTITLEMENT_CODE
    @@PENDING_ENTITLEMENT_CODE
  end
  
  def self.LICENSE_COUNT_DISCREPANCY_CODE
    @@LICENSE_COUNT_DISCREPANCY_CODE
  end
  
  def self.LICENSE_COUNT_INTEGRITY_PROBLEM_CODE
    @@LICENSE_COUNT_INTEGRITY_PROBLEM_CODE
  end
  
  def self.SC_LICENSING_ACTIVATION_CODE
    @@SC_LICENSING_ACTIVATION_CODE
  end
  
  def self.PENDING_LICENSE_COUNT_CHANGE_CODE
    @@PENDING_LICENSE_COUNT_CHANGE_CODE
  end
  
  def self.pending_entitlement
    TaskType.find_by_code(TaskType.PENDING_ENTITLEMENT_CODE)
  end
  
  
end

# == Schema Information
#
# Table name: task_types
#
#  id            :integer(10)     not null, primary key
#  code          :string(5)       not null
#  description   :string(255)     not null
#  user_type     :string(1)       default("a"), not null
#  priority      :integer(10)     default(0), not null
#  display_order :integer(10)
#

