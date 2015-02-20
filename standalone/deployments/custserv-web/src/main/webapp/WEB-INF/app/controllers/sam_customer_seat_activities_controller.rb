require 'java'

begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end

class SamCustomerSeatActivitiesController < SamCustomersController

  before_filter :set_breadcrumb, :load_required_js_libraries

  layout 'default'
  def index

    conditions_clause = "sp.sam_customer_id =" + @sam_customer.id.to_s
    #if (sa.updated_at>DATE_SUB( NOW(),INTERVAL 14 DAY))
    if (params[:status])
      conditions_clause += " AND sa.status = 5 AND sa.updated_at > DATE_SUB(NOW(), INTERVAL 14 DAY)"
    end

    @seat_activities = SeatActivity.paginate(:all, :select => "sa.*, sp.id as seat_pool_id, sa.conversation_instance_id, ci.agent_id, crt.name as result_name,
    													subcom.name as subcommunity_name, u.first_name, u.last_name, u.id as user_id, ss.enforce_school_max_enroll_cap",
    :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id \
                                                    inner join subcommunity subcom on sp.subcommunity_id = subcom.id \
                                                    left join users u on sa.user_id = u.id \
                                                    inner join sam_server ss on sp.sam_server_id = ss.id
                                                    left join conversation_instance ci on sa.conversation_instance_id = ci.id
                                                    left join conversation_result_type crt on ci.result_type_id = crt.id
                                                    left join agent a on ci.agent_id = a.id",
    :page => params[:page],
    :conditions => conditions_clause,
    :order => "sa.created_at desc",
    :per_page => PAGINATION_ROWS_PER_PAGE)
  end

  #################
  # AJAX ROUTINES #
  #################

  #Cancel a single unfinished seat activity at a server
  def cancel_seat_activity
    seat_pool_service = SC.getBean("seatPoolService")
    # revertSeatActivity checks for Pending and Unstarted transactions
    if (!seat_pool_service.revertSeatActivity(params[:id].to_i, "CSA", current_user.id))
      seat_activity = SeatActivity.find(params[:id])
      return_text = "&nbsp;" + translate_seat_activity_status(seat_activity)
    else
      return_text = "&nbsp;Cancelled"
    end
    render(:text => return_text)
  end

  #Cancel all unfinished seat activities for the given SeatActitity IDs, which may span multiple SamServers at a given SamCustomer.
  # TODO: when this is moved to WebAPI, use a single request for all seat activities, not one for each. - MOD
  def cancel_all_seat_activities
    seat_activity_ids = params[:seat_activity_ids]
    
    if seat_activity_ids && seat_activity_ids.any?
      seat_pool_service = SC.getBean("seatPoolService")
      seat_activity_ids.each do |seat_activity_id|
        # revertSeatActivity checks for Pending and Unstarted transactions
        seat_pool_service.revertSeatActivity(seat_activity_id.to_i, "CSA", current_user.id.to_i) # seat_activity_id is of type String, need to convert.
      end
      
      flash[:msg_type] = 'info'
      flash[:notice] = 'All Pending and Unstarted Transactions Cancelled Successfully'
    else
      flash[:msg_type] = 'error'
      flash[:notice] = 'Error encountered attempting to cancel pending license transactions.'
    end
    
    # :collection => {:operate_on => :get} route for :sam_servers make this work
    redirect_to :controller => :sam_servers, :action => :operate_on
  end

  def freeze_seat_activity
    seat_pool_service = SC.getBean("seatPoolService")
    if (!seat_pool_service.freezeSeatActivity(params[:id].to_i, current_user.id))
      seat_activity = SeatActivity.find(params[:id])
      return_text = "&nbsp;" + translate_seat_activity_status(seat_activity)
    else
      return_text = "&nbsp;Frozen"
    end
    render(:text => return_text)
  end

  def update_seat_activities
    #puts "params: #{params.to_yaml}"
    seat_activities = SeatActivity.paginate(:all, :select => "sa.*, sp.id as seat_pool_id, sa.conversation_instance_id, ci.agent_id, crt.name as result_name,
    													subcom.name as subcommunity_name, u.first_name, u.last_name, u.id as user_id, ss.enforce_school_max_enroll_cap",
    :joins => "sa inner join seat_pool sp on sa.seat_pool_id = sp.id \
                                                    inner join subcommunity subcom on sp.subcommunity_id = subcom.id \
                                                    left join users u on sa.user_id = u.id \
                                                    inner join sam_server ss on sp.sam_server_id = ss.id
                                                    left join conversation_instance ci on sa.conversation_instance_id = ci.id
                                                    left join conversation_result_type crt on ci.result_type_id = crt.id
                                                    left join agent a on ci.agent_id = a.id", :page => params[:page],
    :conditions => ["sp.sam_customer_id = ?", @sam_customer.id], :order => seat_activity_sort_by_param(params[:sort]),
    :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "seat_pools/seat_activity_table",
    :locals => {:seat_activity_collection => seat_activities,
      :status_indicator => params[:status_indicator],
      :update_element => params[:update_element],
      :sam_server => nil,
      :sam_customer_id => params[:sam_customer_id],
      :show_subcommunity => true}, :layout => false)
  end

  private

  def seat_activity_sort_by_param(sort_by_arg)
    case sort_by_arg

    when "seat_activity_id" then "sa.id"
    when "server_name" then "ss.name, sa.created_at"
    when "starting_count" then "sa.starting_count"
    when "delta" then "sa.delta"
    when "done" then "sa.done, sa.created_at"
    when "created_at" then "sa.created_at"
    when "user" then "u.last_name"
    when "subcommunity_name" then "subcommunity_name, sa.created_at"
    when "status" then "sa.status, sa.created_at desc"

    when "seat_activity_id_reverse" then "sa.id desc"
    when "server_name_reverse" then "ss.name desc, sa.created_at"
    when "starting_count_reverse" then "sa.starting_count desc"
    when "delta_reverse" then "sa.delta desc"
    when "done_reverse" then "sa.done desc, sa.created_at"
    when "created_at_reverse" then "sa.created_at desc"
    when "user_reverse" then "u.last_name desc"
    when "subcommunity_name_reverse" then "subcommunity_name desc, sa.created_at"
    when "status_reverse" then "sa.status desc, sa.created_at desc"

    else "sa.created_at desc"
    end
  end

  def set_breadcrumb
    @site_area_code = SEAT_ACTIVITY_CODE
  end

  def load_required_js_libraries
    @prototype_required = true
  end

end