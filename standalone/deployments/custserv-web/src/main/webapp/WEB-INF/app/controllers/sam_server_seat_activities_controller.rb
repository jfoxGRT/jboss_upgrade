class SamServerSeatActivitiesController < SamServersController
  
  def index
    @seat_activities = SeatActivity.paginate(:all, :select => "sa.*, sp.id as seat_pool_id, sa.conversation_instance_id, ci.agent_id, crt.name as result_name,
																s.name as subcommunity_name, u.last_name, u.first_name, ss.enforce_school_max_enroll_cap", 
                                         :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id
                                                    left join users u on sa.user_id = u.id
                                                    inner join subcommunity s on sp.subcommunity_id = s.id
													                          inner join sam_server ss on sp.sam_server_id = ss.id
                                                    left join conversation_instance ci on sa.conversation_instance_id = ci.id
                                                    left join conversation_result_type crt on ci.result_type_id = crt.id
                                                    left join agent a on ci.agent_id = a.id", :page => params[:page],
                                         :conditions => ["sp.sam_customer_id = ? and sp.sam_server_id = ?", @sam_customer.id, @sam_server.id], :order => "sa.status, sa.created_at desc",
                                         :per_page => PAGINATION_ROWS_PER_PAGE)
  end
    
  #################
  # AJAX ROUTINES #
  #################
  
  def update_seat_activities
    puts "params: #{params.to_yaml}"
    seat_activities = SeatActivity.paginate(:all, :select => "sa.*, sp.id as seat_pool_id, sa.conversation_instance_id, ci.agent_id, crt.name as result_name,
																s.name as subcommunity_name, u.last_name, u.first_name, ss.enforce_school_max_enroll_cap", 
                                         :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id
                                                    inner join users u on sa.user_id = u.id
                                                    inner join subcommunity s on sp.subcommunity_id = s.id
													                          inner join sam_server ss on sp.sam_server_id = ss.id
                                                    left join conversation_instance ci on sa.conversation_instance_id = ci.id
                                                    left join conversation_result_type crt on ci.result_type_id = crt.id
                                                    left join agent a on ci.agent_id = a.id", :page => params[:page],
                                         :conditions => ["sp.sam_customer_id = ? and sp.sam_server_id = ?", @sam_customer.id, @sam_server.id], :order => seat_activity_sort_by_param(params[:sort]),
                                         :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "seat_pools/seat_activity_table", 
           :locals => {:seat_activity_collection => seat_activities,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :sam_customer_id => params[:sam_customer_id],
                       :sam_server => @sam_server,
                       :show_subcommunity => true}, :layout => false)
  end
  
  private
  
  def seat_activity_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "seat_activity_id" then "sa.id"
      when "starting_count" then "sa.starting_count"
      when "delta" then "sa.delta"
      when "done" then "sa.status, sa.created_at"
      when "created_at" then "sa.created_at"
      when "user" then "u.last_name"
      when "subcommunity_name" then "subcommunity_name"
    
      when "seat_activity_id_reverse" then "sa.id desc"
      when "starting_count_reverse" then "sa.starting_count desc"
      when "delta_reverse" then "sa.delta desc"
      when "done_reverse" then "sa.status desc, sa.created_at"
      when "created_at_reverse" then "sa.created_at desc"
      when "user_reverse" then "u.last_name desc"
      when "subcommunity_name_reverse" then "subcommunity_name desc"
      
      else "sa.status, sa.created_at"
    end
  end
  
end
