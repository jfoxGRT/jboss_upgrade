class SubcommunitySeatPoolsController < SeatPoolsController
  
  layout 'cs_layout'
  
  def index
    @subcommunity = Subcommunity.find(params[:subcommunity_id])
    @seat_pools = SeatPool.paginate(:all, :page => params[:page], :select => "sp.*, ss.name, ss.id as server_id", :joins => "sp left outer join sam_server ss on sp.sam_server_id = ss.id",
                                     :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ?", @sam_customer.id, @subcommunity.id],
                                     :per_page => PAGINATION_ROWS_PER_PAGE)    
  end
  
  def show
    @subcommunity = Subcommunity.find(params[:subcommunity_id])
    @seat_pool = SeatPool.find(params[:id])
    @seat_activities = paginate_seat_activities(params[:id], params[:page], params["sort"])
  end
  
  def update
  end

  #################
  # AJAX ROUTINES #
  #################
  
  def update_seat_pools
    seat_pools = SeatPool.paginate(:all, :page => params[:page], :select => "sp.*, ss.name, ss.id as server_id", :joins => "sp left outer join sam_server ss on sp.sam_server_id = ss.id",
                                     :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ?", params[:sam_customer_id], params[:subcommunity_id]],
                                     :order => seat_pools_sort_by_param(params["sort"]),
                                     :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "seat_pools_table", 
           :locals => {:seat_pool_collection => seat_pools,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :sam_customer_id => params[:sam_customer_id],
                       :subcommunity_id => params[:subcommunity_id]})
  end
  
  def update_seat_activities
    #puts "params in update_seat_activities: #{params.to_yaml}"
    seat_activities = paginate_seat_activities(params[:id], params[:page], params["sort"])
    render(:partial => "seat_pools/seat_activity_table", 
           :locals => {:seat_activity_collection => seat_activities,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :seat_pool_id => params[:id],
                       :sam_customer_id => params[:sam_customer_id]}, :layout => false)
  end
  
  def seat_pools_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "seat_pool_id" then "sp.id"
      when "server_id" then "ss.id"
      when "server_name" then "ss.name"
      when "seat_count" then "sp.seat_count"
      when "created_at" then "sp.created_at"
      when "updated_at" then "sp.updated_at"
      
      when "seat_pool_id_reverse" then "sp.id desc"
      when "server_id_reverse" then "ss.id desc"
      when "server_name_reverse" then "ss.name desc"
      when "seat_count_reverse" then "sp.seat_count desc"
      when "created_at_reverse" then "sp.created_at desc"
      when "updated_at_reverse" then "sp.updated_at desc"
    end
  end
  
end
