class Alert < ActiveRecord::Base
  set_table_name "alert"
  
  @@AGENT_EVENT_PROBLEM_CODE = "AGENT_EVENT_PROBLEM"
  @@AGENT_EVENT_INFO_CODE = "AGENT_EVENT_INFO"
  @@UNASSIGNED_ENTITLEMENT_CODE = "INDETERMINABLE_ROOT_ORG"
  @@NO_ACCOUNT_ADMINISTRATOR_CODE = "NO_USERS"
  @@LICENSE_COUNT_DISCREPANCY_CODE = "LICENSING_BALANCE"
  @@LICENSE_COUNT_INTEGRITY_CODE = "LICENSING_INTEGRITY"
  @@PENDING_LICENSE_COUNT_CHANGE_CODE = "LICENSE_COUNT_CHANGE"
  @@SC_LICENSING_ACTIVATION_CODE = "SC_LICENSING_ACTIVATION"
  @@ASSIGN_FAIL_CODE = "ASSIGN_FAIL"
  @@ASSIGN_SUCCEED_CODE = "ASSIGN_SUCCEED"
  @@CONVO_EXCEPT_CODE = "CONVO_EXCEPT"
  @@SUPER_ADMIN_REQUEST_CODE = "NSA"
  
  def self.AGENT_EVENT_PROBLEM_CODE
    @@AGENT_EVENT_PROBLEM_CODE
  end
  
  def self.AGENT_EVENT_INFO_CODE
    @@AGENT_EVENT_INFO_CODE
  end
  
  def self.UNASSIGNED_ENTITLEMENT_CODE
    @@UNASSIGNED_ENTITLEMENT_CODE
  end
  
  def self.NO_ACCOUNT_ADMINISTRATOR_CODE
    @@NO_ACCOUNT_ADMINISTRATOR_CODE
  end
  
  def self.LICENSE_COUNT_DISCREPANCY_CODE
    @@LICENSE_COUNT_DISCREPANCY_CODE
  end
  
  def self.SC_LICENSING_ACTIVATION_CODE
    @@SC_LICENSING_ACTIVATION_CODE
  end
  
  def self.LICENSE_COUNT_INTEGRITY_CODE
    @@LICENSE_COUNT_INTEGRITY_CODE
  end
  
  def self.PENDING_LICENSE_COUNT_CHANGE_CODE
    @@PENDING_LICENSE_COUNT_CHANGE_CODE
  end
  
  def self.ASSIGN_FAIL_CODE
    @@ASSIGN_FAIL_CODE
  end
  
  def self.ASSIGN_SUCCEED_CODE
    @@ASSIGN_SUCCEED_CODE
  end
  
  def self.CONVO_EXCEPT_CODE
    @@CONVO_EXCEPT_CODE
  end
  
  def self.SUPER_ADMIN_REQUEST_CODE
    @@SUPER_ADMIN_REQUEST_CODE
  end  
  
  def self.getUnassignedEntitlementsAlert()
    Alert.find_by_code("INDETERMINABLE_ROOT_ORG")
  end
  
  def self.getUnassignedSamCustomerAlert()
    Alert.find_by_code("UNASSIGNED_SAM_CUSTOMER")
  end
  
end

# == Schema Information
#
# Table name: alert
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)     not null
#  msg_type    :string(255)     not null
#  description :string(255)
#  user_type   :string(1)       default("a")
#  priority    :integer(10)     default(0), not null
#

