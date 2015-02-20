class AuditMessage < ActiveRecord::Base
  set_table_name "audit_message"
  
	@@SSSI_ALLOCATED_COUNT_PREFIX = "A_";
	@@SSSI_ENROLLED_COUNT_PREFIX = "U_";
	@@SSSE_ALLOCATED_COUNT_PREFIX = "S_";
	@@SSSE_ENROLLED_COUNT_PREFIX = "E_";
	@@SEAT_POOL_COUNT_PREFIX = "P_";
	@@SAM_SERVER_PREFIX = "S"
	
	def self.SSSI_ALLOCATED_COUNT_PREFIX
		@@SSSI_ALLOCATED_COUNT_PREFIX
	end
	
	def self.SSSI_ENROLLED_COUNT_PREFIX
		@@SSSI_ENROLLED_COUNT_PREFIX
	end
	
	def self.SSSE_ALLOCATED_COUNT_PREFIX
		@@SSSE_ALLOCATED_COUNT_PREFIX
	end
	
	def self.SSSE_ENROLLED_COUNT_PREFIX
		@@SSSE_ENROLLED_COUNT_PREFIX
	end
	
	def self.SEAT_POOL_COUNT_PREFIX
		@@SEAT_POOL_COUNT_PREFIX
	end
	
	def self.SAM_SERVER_PREFIX
		@@SAM_SERVER_PREFIX
	end
  
  has_many :audit_message_props, :foreign_key => "audit_message_id", :class_name => "AuditMessageProp"
  
  def self.gather_audit_message_data_by_resource_id(resource_id)
    audit_messages = AuditMessage.find(:all, :select => "amp.*, am.*", :joins => "am inner join audit_message_prop amp on amp.audit_message_id = am.id",
                          :conditions => ["am.resource_id = ?", resource_id])
    audit_message_hash = {}
    audit_messages.each do |am|
      audit_message_hash[am.audit_message_id] = Array.new if audit_message_hash[am.audit_message_id].nil?
      audit_message_hash[am.audit_message_id] << am
    end
    return audit_message_hash
  end
  
  def self.find_seat_pool_messages(seat_pool_id)
	AuditMessage.find(:all, :select => "am.*, amp.value, count(em.id) as esb_message_count", 
	          :joins => "am inner join audit_message_prop amp on amp.audit_message_id = am.id left join esb_message em on em.reference_message_token = am.token", 
						:conditions => ["am.resource_id = ? and amp.name = 'seatCount'", AuditMessage.SEAT_POOL_COUNT_PREFIX + seat_pool_id.to_s], :group => "am.id", :order => "id desc", :limit => "400")
  end
  
  def self.find_last_seat_pool_message_before(seat_pool_id, p_time)
	AuditMessage.find(:first, :select => "am.*, amp.value", :joins => "am inner join audit_message_prop amp on amp.audit_message_id = am.id", 
						:conditions => ["am.resource_id = ? and amp.name = 'seatCount' and am.timestamp < ?", AuditMessage.SEAT_POOL_COUNT_PREFIX + seat_pool_id.to_s, p_time], :order => "id desc", :limit => "1")
  end

	def self.find_all_seat_pool_messages_for_subcommunity(sam_customer_id, subcommunity_id)
		AuditMessage.find(:all, :select => "am.*, ss.id as server_id, ss.name as server_name, amp1.value", 
							:joins => "am inner join audit_message_prop amp3 on (amp3.audit_message_id = am.id and amp3.name = 'subcommunityId' and amp3.value = '#{subcommunity_id}')
										inner join audit_message_prop amp4 on (amp4.audit_message_id = am.id and amp4.name = 'serverId')
										left join sam_server ss on ss.id = amp4.value
							 			inner join audit_message_prop amp1 on (amp1.audit_message_id = am.id and amp1.name = 'seatCount')", 
							 			:conditions => ["am.sam_customer_id = ? and am.resource_id like '%P_%'", sam_customer_id], :group => "am.id", :order => "id desc", :limit => "400")
	end
  
  def self.find_server_license_count_messages(sssi_id)
	AuditMessage.find(:all, :select => "am.*, amp.value, count(em.id) as esb_message_count", 
	                  :joins => "am inner join audit_message_prop amp on amp.audit_message_id = am.id left join esb_message em on em.reference_message_token = am.token", 
						        :conditions => ["am.resource_id = ? and amp.name = 'seatCount'", AuditMessage.SSSI_ALLOCATED_COUNT_PREFIX + sssi_id.to_s], :group => "am.id", :order => "id desc", :limit => "400")
  end

	def self.find_all_server_license_count_messages_for_subcommunity(sam_customer_id, subcommunity_id)
		AuditMessage.find(:all, :select => "am.*, ss.id as server_id, ss.name as server_name, amp1.value", 
							:joins => "am inner join audit_message_prop amp3 on (amp3.audit_message_id = am.id and amp3.name = 'subcommunityId' and amp3.value = '#{subcommunity_id}')
										inner join audit_message_prop amp4 on (amp4.audit_message_id = am.id and amp4.name = 'serverId')
										left join sam_server ss on ss.id = amp4.value
							 			inner join audit_message_prop amp1 on (amp1.audit_message_id = am.id and amp1.name = 'seatCount')",
						 :conditions => ["am.sam_customer_id = ? and am.resource_id like '%A_%'", sam_customer_id], :group => "am.id", :order => "id desc", :limit => "400")
	end

	
  
end
# == Schema Information
#
# Table name: audit_message
#
#  id              :integer(10)     not null, primary key
#  timestamp       :datetime        not null
#  clazz           :string(255)
#  event_type      :string(255)
#  token           :string(255)
#  resource_id     :string(30)
#  reason          :string(255)
#  sam_customer_id :integer(10)
#

