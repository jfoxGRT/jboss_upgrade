class SeatActivity < ActiveRecord::Base
  set_table_name "seat_activity"
  
  STATUS_UNFINISHED = 0 
  STATUS_FINISHED = 1
  STATUS_CANCELLED = 2
  STATUS_INTERRUPTED = 3 #Also known as 'COMBINED'
  STATUS_FROZEN = 4 
  STATUS_CONVERSATION_FAILURE = 5
  STATUS_PENDING_START = 6
  
  TYPE_USER_MOVE = 'm'
  TYPE_SYSTEM_GENERATED = 's'
  TYPE_REMEDIATE_SERVER = 'r'
  TYPE_ALLOCATION_LEVEL_CHANGE = 'l'
  
  belongs_to :seat_pool
  belongs_to :conversation_instance
  belongs_to :user
  belongs_to :source_seat_pool
  
  def self.active_conversation(server, subcom)
    cnt = SeatActivity.count(:all, 
      :joins => "as sa inner join seat_pool as sp on sa.seat_pool_id = sp.id",
      :conditions => ["sp.sam_server_id = ? and 
                       sp.subcommunity_id = ? and 
                       sa.status = ? and 
                       sa.conversation_instance_id IS NOT NULL",
         server.id, subcom.id, SeatActivity::STATUS_UNFINISHED])
    cnt.nil? ? 0 : cnt
    return (cnt > 0)  
  end
  
  #determine if a seat activity can be cancelled
  def self.is_cancellable(sa)
     result = (sa.status == (SeatActivity::STATUS_UNFINISHED || SeatActivity::STATUS_PENDING_START) && 
                !(sa.seat_pool.sam_server.enforce_school_max_enroll_cap))
      
     return result
  end
  
  def self.find_frozen_by_target_seat_pool(seat_pool)
		unstarted_seat_activities = SeatActivity.find(:all, :select => "sa.*", :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id", 
											:conditions => ["sa.seat_pool_id = ? and conversation_instance_id is null and status = ?",
											seat_pool.id, SeatActivity::STATUS_FROZEN])
		raise SeatActivityIntegrityException.new(seat_pool) if unstarted_seat_activities.length > 1
		unstarted_seat_activities.length > 0 ? unstarted_seat_activities[0] : nil
	end
	
	def self.find_unstarted_by_target_seat_pool(seat_pool)
		unstarted_seat_activities = SeatActivity.find(:all, :select => "sa.*", :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id", 
											:conditions => ["sa.seat_pool_id = ? and conversation_instance_id is null and status = ?",
											seat_pool.id, SeatActivity::STATUS_UNFINISHED])
		raise SeatActivityIntegrityException.new(seat_pool) if unstarted_seat_activities.length > 1
		unstarted_seat_activities.length > 0 ? unstarted_seat_activities[0] : nil
	end
	
	
	def self.find_incomplete_by_sam_servers(sam_servers)
	  incomplete_seat_activities = Array.new
	  
	  sam_servers.each do |sam_server|
	    partial_results = find_incomplete_by_sam_server(sam_server)
	    incomplete_seat_activities << partial_results
	  end
	  
    incomplete_seat_activities.flatten!
  end
	
	
	def self.find_incomplete_by_sam_server(sam_server)
	  SeatActivity.find(:all, :select => "sa.*", :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id",
	                    :conditions => ["sp.sam_server_id = ? and status = ?", sam_server.id, SeatActivity::STATUS_UNFINISHED])
	end
  
  def self.find_activity_count(sam_customer)
                 conditions_clause = "sa.status = 5 AND sa.updated_at > DATE_SUB(NOW(), INTERVAL 14 DAY)"
                      conditions_clause += "and sp.sam_customer_id =" + sam_customer.id.to_s

    seat_count = SeatActivity.find(:first, :select => "count(sa.id) as count", :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id",
                      :conditions => conditions_clause)
                      
         
                      return seat_count.count.to_i
          
  end
	
	def self.find_frozen_remediated(server, subcommunity = nil)
    if (subcommunity.nil?)
      frozen_remediated_seat_activities = SeatActivity.find(:all, :select => "sa.*", 
              :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id", 
							:conditions => ["sp.sam_server_id = ? and conversation_instance_id is null and activity_type = ? and status = ?",
							server.id, SeatActivity::TYPE_REMEDIATE_SERVER, SeatActivity::STATUS_FROZEN])
    else
      frozen_remediated_seat_activities = SeatActivity.find(:all, :select => "sa.*", 
              :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id", 
							:conditions => ["sp.sam_server_id = ? and sp.subcommunity_id = ? and conversation_instance_id is null and activity_type = ? and status = ?",
							server.id, subcommunity.id, SeatActivity::TYPE_REMEDIATE_SERVER, SeatActivity::STATUS_FROZEN])
		end
		if (frozen_remediated_seat_activities.length > 0)
		  logger.info("frozen seat activity ids: #{frozen_remediated_seat_activities[0].id}")
		  return frozen_remediated_seat_activities[0]
		end
		return nil
  end
  
end

# == Schema Information
#
# Table name: seat_activity
#
#  id                       :integer(10)     not null, primary key
#  seat_pool_id             :integer(10)     not null
#  starting_count           :integer(10)
#  delta                    :integer(10)     not null
#  created_at               :datetime
#  conversation_instance_id :integer(10)
#  status                   :integer(10)
#  user_id                  :integer(10)
#  source_seat_pool_id      :integer(10)
#  activity_type            :string(1)       default("m"), not null
#  updated_at               :datetime
#

