class AlertInstance < ActiveRecord::Base
  set_table_name "alert_instance"
  belongs_to :alert
  belongs_to :conversation_instance
  belongs_to :server, :class_name => "SamServer", :foreign_key => "server_id"
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :org1, :class_name => "Org", :foreign_key => "org1_id"
  belongs_to :org2, :class_name => "Org", :foreign_key => "org2_id"
  belongs_to :assigned_user, :class_name => "User", :foreign_key => "assigned_user_id"
  belongs_to :assigning_user, :class_name => "User", :foreign_key => "assigning_user_id"
  belongs_to :entitlement, :class_name => "Entitlement", :foreign_key => "entitlement_id"
  belongs_to :sam_customer
  belongs_to :task
  belongs_to :agent, :class_name => "Agent", :foreign_key => "agent_id" 
  has_many :alert_params, :foreign_key => "alert_instance_id", :class_name => "AlertParam"
  
  def self.find_by_alert_code(alertCode)
    AlertInstance.find(:all, :joins => "as ai inner join alert a on ai.alert_id = a.id", 
                                 :conditions => ["a.code = ?", alertCode])
  end
  
  def self.group_recent_by_alert(user)
    today = Date.today
    start_date = today - 365
    conditions_clause = "ai.created_at between '#{start_date} 00:00:00' and '#{today} 23:59:59'"
    conditions_clause += " and a.user_type = 's'" if (user.isScholasticType)
    AlertInstance.find(:all, :select => "a.id, a.description, count(*) as the_count", :joins => "ai inner join alert a on ai.alert_id = a.id", :conditions => conditions_clause, :group => "a.id", :order => "a.description")
  end
  
  def self.find_recent_by_alert_id(user, alert_id)
    today = Date.today
    start_date = today - 365
    joins_clause = "ai left join sam_customer sc on ai.sam_customer_id = sc.id "
    conditions_clause = "ai.created_at > '#{start_date} 00:00:00' and ai.alert_id = ?"
    if (user.isScholasticType)
      conditions_clause += " and a.user_type = 's'"
      joins_clause += " inner join alert a on ai.alert_id = a.id"
    end
    AlertInstance.find(:all, :select => "ai.*, sc.name", :joins => joins_clause, 
                       :conditions => [conditions_clause, alert_id], :order => "ai.created_at desc")
  end
  
  def self.group_recent_by_sam_customer(alert_id)
      conditions_clause = "ai.created_at > '#{start_date} 00:00:00' and ai.alert_id = ?"
      AlertInstance.find(:all, :select => "sc.id as sam_customer_id, sc.name as sam_customer_name, a.description as alert_type, count(ai.id) as alert_count",
                          :conditions => [conditions_clause, alert_id], :group => "sc.id", :order => "alert_count desc")  
  end
  
  def self.group_recent_aep_by_sam_customer
    alert_id = Alert.find_by_code("AGENT_EVENT_PROBLEM").id
    today = Date.today
    start_date = today - 1000
    joins_clause = "ai left join sam_customer sc on ai.sam_customer_id = sc.id "
    conditions_clause = "ai.created_at > '#{start_date} 00:00:00' and ai.alert_id = ?"
    AlertInstance.find(:all, :select => "sc.id as sam_customer_id, sc.name as sam_customer_name, substring_index(ai.message, ' ', 1) as alert_type, count(ai.id) as alert_count", :joins => joins_clause, 
                       :conditions => [conditions_clause, alert_id], :group => "sc.id, substring_index(ai.message, ' ', 1)", :order => "alert_count desc")
  end
  
  
end

# == Schema Information
#
# Table name: alert_instance
#
#  id                       :integer(10)     not null, primary key
#  alert_id                 :integer(10)     not null
#  message                  :string(4096)
#  conversation_instance_id :integer(10)
#  server_id                :integer(10)
#  user_id                  :integer(10)
#  created_at               :datetime        not null
#  long_message             :text
#  entitlement_id           :integer(10)
#  sam_customer_id          :integer(10)
#  agent_id                 :integer(10)
#  task_id                  :integer(10)
#  old_sam_customer_id      :integer(10)
#

