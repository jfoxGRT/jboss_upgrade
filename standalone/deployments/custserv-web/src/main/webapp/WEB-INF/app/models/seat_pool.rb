class SeatPool < ActiveRecord::Base
  set_table_name "seat_pool"
  
  belongs_to :sam_customer
  belongs_to :subcommunity
  belongs_to :sam_server
  
  has_many :seat_activities, :foreign_key => "seat_pool_id", :class_name => "SeatActivity"
      
  def self.find_seat_count_during(seat_pool_id, p_time)
    am = AuditMessage.find_last_seat_pool_message_before(seat_pool_id, p_time)
    am.nil? ? nil : am.value
  end    
      
      
  def self.entitled_seat_count_for_sam_customer(samCustomer, subcom)
    self.entitled_seat_count_on_active_servers(samCustomer, subcom) + 
    self.entitled_seat_count_unassigned_to_a_server(samCustomer, subcom)
  end
        
  def self.entitled_seat_count_on_active_servers(samCustomer, subcom)
    cnt = SeatPool.sum(:seat_count, 
      :joins => "as sp inner join sam_server as ss on sp.sam_server_id = ss.id", 
      :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and ss.status = 'a'", samCustomer.id, subcom.id])
    cnt.nil? ? 0 : cnt 
  end
  
  def self.entitled_seat_count_unassigned_to_a_server(samCustomer, subcom)
    cnt = SeatPool.sum(:seat_count,
      :joins => "as sp", 
      :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and sp.sam_server_id IS NULL", samCustomer.id, subcom.id])
    cnt.nil? ? 0 : cnt 
  end
  
  def self.entitled_seat_count_for_server(samCustomer, subcom, server)
    cnt = SeatPool.sum(:seat_count,
      :joins => "as sp inner join sam_server as ss on sp.sam_server_id = ss.id", 
      :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and sp.sam_server_id = ? and ss.status = 'a'", \
         samCustomer.id, subcom.id, server.id])
    cnt.nil? ? 0 : cnt   
  end
  
    
  def self.obtain_seat_pool(sam_customer, subcommunity, sam_server)
    if (sam_server.nil?)
      pool = SeatPool.find(:first, :conditions => ["sam_customer_id = ? and subcommunity_id = ? and sam_server_id is null", sam_customer.id, subcommunity.id])
    else
      pool = SeatPool.find(:first, :conditions => ["sam_customer_id = ? and subcommunity_id = ? and sam_server_id = ?", sam_customer.id, subcommunity.id, sam_server.id])
    end
    return pool if (!pool.nil?)
    return SeatPool.create(:sam_customer => sam_customer, :subcommunity => subcommunity, :sam_server => sam_server, :seat_count => 0)
  end
  
  def self.find_seat_pool(sam_customer, subcommunity, sam_server)
    #puts "sam_customer: #{sam_customer}"
    #puts "subcommunity: #{subcommunity}"
    if (sam_server.nil?)
      pool = SeatPool.find(:first, :conditions => ["sam_customer_id = ? and subcommunity_id = ? and sam_server_id is null", sam_customer.id, subcommunity.id])
    else
      pool = SeatPool.find(:first, :conditions => ["sam_customer_id = ? and subcommunity_id = ? and sam_server_id = ?", sam_customer.id, subcommunity.id, sam_server.id])
    end
    return pool
  end
  
  def self.server_pending_successful_reallocations(sc, subcom)
    SeatPool.find(:first, :select => "sp.*",
                  :joins => "as sp inner join seat_activity as sa on sa.seat_pool_id = sp.id \
                             inner join conversation_instance as ci on sa.conversation_instance_id = ci.id",
                  :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and sa.status = 1 and ((sa.current_count + sa.delta) != sa.count_set_on_server)",
                                  sc.id, subcom.id], :order => "sa.id desc")
  end
  
  def self.find_by_pending_reallocations(sam_customer_id, subcommunity_id)
    SeatPool.find(:first, :select => "seat_pool.*", :joins => "inner join seat_activity on seat_activity.seat_pool_id = seat_pool.id", 
                  :conditions => ["seat_pool.sam_customer_id = ? and seat_pool.subcommunity_id = ? and seat_activity.status = 0", sam_customer_id, subcommunity_id])
  end
  
  
  # source pool will ALWAYS be 'unallocated'
	def self.move_seats(source_pool, target_pool, subcommunity, delta_for_target, user_id)
	
		logger.info("Moving from seat pool ID: #{source_pool.id} to seat pool ID: #{target_pool.id}")
		
		return false if SeatActivity.active_conversation(target_pool.sam_server, subcommunity)
		
		raise Exception.new("Unstarted seat activity not allowed during remediation") if !SeatActivity.find_unstarted_by_target_seat_pool(target_pool).nil?

		# set the old seat activity as interrupted (if there is any outstanding seat activity)
		old_seat_activity = SeatActivity.find_frozen_by_target_seat_pool(target_pool)
		old_seat_activity.status = SeatActivity::STATUS_INTERRUPTED if !old_seat_activity.nil?
		#sam_customer = source_pool.sam_customer
		#starting_source_pool_count = source_pool.seat_count
		
		# adjust the source pool's count
		source_pool.seat_count -= delta_for_target
		
		# adjust the target pool's count
		starting_target_pool_count = target_pool.seat_count
		target_pool.seat_count += delta_for_target
		
		# now calculate the NET delta, factoring in any previous (interrupted) seat activity
		# if there IS old seat activity, then the net delta = (new server pool's count) - (old seat activity's starting count)
		# if there is NOT any old seat activity, then the net delta is simply the delta_for_target param
		net_delta = (!old_seat_activity.nil?) ? (target_pool.seat_count - old_seat_activity.starting_count) : delta_for_target
		#SeatActivity.create(:seat_pool_id => source_pool.id, :starting_count => starting_source_pool_count, 
		#	:delta => (delta_for_target * -1), :user_id => user_id, :done => (source_server.server_type == SamServer::TYPE_UNREGISTERED_GENERIC)) if (!source_server.nil?)
		
		# now calculate the new starting count
		new_starting_count = ((!old_seat_activity.nil?) ? old_seat_activity.starting_count : starting_target_pool_count)
		
		# get the target server
		target_server = target_pool.sam_server
		
		# persist all the changes
		old_seat_activity.save if !old_seat_activity.nil?
		source_pool.save
		target_pool.save
		SeatActivity.create(:seat_pool_id => target_pool.id, :starting_count => new_starting_count, :source_seat_pool_id => source_pool.id,
			:delta => net_delta, :user_id => user_id, :status => SeatActivity::STATUS_FROZEN, :activity_type => SeatActivity::TYPE_REMEDIATE_SERVER)
			
		# send the messages
		#message_sender = SC.getBean("messageSender")
		#message_sender.sendSeatCountFromUi(source_pool.id, "CHANGE", "RS", source_pool.seat_count)
		#message_sender.sendSeatCountFromUi(target_pool.id, "CHANGE", "RS", target_pool.seat_count)
		
		return true	
			
	end
	
	def self.seat_count_unassigned(samCustomer, subcom)
	    cnt = SeatPool.sum(:seat_count,
	      :conditions => ["seat_pool.sam_customer_id = ? and seat_pool.subcommunity_id = ? and seat_pool.sam_server_id IS NULL", samCustomer.id, subcom.id])
	    cnt.nil? ? 0 : cnt 
  	end
  
  def self.seat_count_for_server(server, subcom)
    cnt = SeatPool.sum(:seat_count,
      :joins => "inner join sam_server as ss on seat_pool.sam_server_id = ss.id", 
      :conditions => ["seat_pool.subcommunity_id = ? and seat_pool.sam_server_id = ? and ss.status = 'a'", \
         subcom.id, server.id])
    cnt.nil? ? 0 : cnt   
  end
  
  def self.seat_count_not_enrolled_for_license_activated_server(server, subcom)
    self.seat_count_for_server(server, subcom) - SamServerSubcommunityInfo.enrolled_seat_count_on_server(server, subcom).to_i
  end
  
  
end

# == Schema Information
#
# Table name: seat_pool
#
#  id              :integer(10)     not null, primary key
#  sam_customer_id :integer(10)     not null
#  subcommunity_id :integer(10)     not null
#  sam_server_id   :integer(10)
#  created_at      :datetime
#  updated_at      :datetime
#  seat_count      :integer(10)     not null
#

