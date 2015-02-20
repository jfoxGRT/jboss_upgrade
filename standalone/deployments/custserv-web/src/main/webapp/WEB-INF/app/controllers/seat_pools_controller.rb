begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
class SeatPoolsController < SamCustomerSubcommunitiesController

  # ideally, we don't want the filters running for AJAX actions
  before_filter :load_seat_pool, :except => [:update_seat_pools, :update_seat_activities]
  
  layout 'default'
  
  def index
    @subcommunity = Subcommunity.find(params[:subcommunity_id])
    @seat_pools = SeatPool.paginate(:all, :page => params[:page], :select => "sp.*, ss.name, ss.id as server_id", :joins => "sp left outer join sam_server ss on sp.sam_server_id = ss.id",
                                     :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ?", @sam_customer.id, @subcommunity.id],
                                     :per_page => PAGINATION_ROWS_PER_PAGE)    
  end
  
  def show
    #puts "params: #{params.to_yaml}"
    @seat_pool = SeatPool.find(params[:id])
    #@seat_activities = paginate_seat_activities(params[:id], params[:page], params["sort"])
	  #@seat_pool_msgs = AuditMessage.find_seat_pool_messages(params[:id])
	  @seat_count = SeatPool.find_seat_count_during(params[:id], Time.local(2010,"aug",12,15,0,0))
	  @sssi = nil
	  @server_license_count_msgs = nil
	  @sssi = SamServerSubcommunityInfo.find_by_sam_server_and_subcommunity(@seat_pool.sam_server, @seat_pool.subcommunity) if !@seat_pool.sam_server.nil?
	  #@server_license_count_msgs = AuditMessage.find_server_license_count_messages(@sssi.id) if !@sssi.nil?
	  @school_enrollments = SamServerSchoolEnrollment.index(@seat_pool.sam_server, @seat_pool.subcommunity) if !@seat_pool.sam_server.nil?
	  #render(:layout => "jquery_for_popup")
	  @widget_list << Widget.new("license_allocation_options", "License Allocation Policy", nil, 600, 700)
	  @widget_list << Widget.new("seat_pool_msgs", "SAMC License Count Audit History", nil, 600, 700)
	  @widget_list << Widget.new("server_license_count_msgs", "Server License Count Audit History", nil, 600, 700)
  end
  
  def edit
    #Look for the from_landscape param, and set it in the session
	if (!params[:from_landscape].nil? && params[:from_landscape] == "y")
		session[:from_landscape_page] = 'true'
	end
		
    @seat_pool = SeatPool.find(params[:id])
    @virtual_count = Entitlement.total_virtual_license_count(@seat_pool.sam_customer, @seat_pool.subcommunity)
    @prototype_required = true
  end
  
  def update
    delta = params[:delta].to_i
    # TODO: make sure that the seat count hasn't changed since!
    seat_pool_service = SC.getBean("seatPoolService")
    if (seat_pool_service.adjustTotalLicenses(params[:id].to_i, delta, current_user.id, params[:user_comment]))
      flash[:notice] = "Successfully applied #{params[:delta]} licenses for #{@subcommunity.name}"
      flash[:msg_type] = "info"
      redirect_to(sam_customer_subcommunity_path(@sam_customer.id, @subcommunity.id))
    else
      raise Exception.new("Could not apply this many licenses.  Please check the delta and try again.")
    end
  rescue Exception => e
      flash[:notice] = "There was a problem with your request: #{e}"
      redirect_to(edit_sam_customer_subcommunity_seat_pool_path(@sam_customer.id, @subcommunity.id, params[:id]))
  end

  def lcd_autoresolve_audit
    @lcds = LicenseCountDiscrepancy.find_by_sql("select id as id, created_at as created_at, sam_server_count as sam_server_count, seat_pool_count as seat_pool_count, entitlement_id as entitlement_id 
      from license_count_discrepancies
	  where sam_server_id = " + params[:samServerId] + " and subcommunity_id = " + params[:subcommunity_id] + " order by created_at desc")
  end
  
  def find_LCD_messages
    @lcd_id = params[:lcd_id]
    
    @lcd_messages = AuditMessage.find(:all, 
                                      :joins => " INNER JOIN license_count_discrepancy_messages lcdm ON audit_message.token = lcdm.message_token",
                                      :conditions => {"lcdm.license_count_discrepancy_id" => params[:lcd_id].to_i},
                                      :order => :id)
    
	 render(:layout => "cs_blank_layout")
  end
  
  def get_LCD_message_props
    @am_id = params[:am_id]
    @lcd_message_props = LicenseCountDiscrepancy.find_by_sql("select amp.id as id, amp.name as name, amp.value 
	  from audit_message_prop amp where audit_message_id = " + params[:am_id] + " order by id")
	render(:layout => "cs_blank_layout")
  end
  
  #################
  # AJAX ROUTINES #
  #################
  
  def seat_pool_msgs
    seat_pool_msgs = AuditMessage.find_seat_pool_messages(params[:id])
    render(:partial => "seat_pool_msgs", :object => seat_pool_msgs)
  end
  
  def server_license_count_msgs
    sssi = nil
    seat_pool = SeatPool.find(params[:id])
    sssi = SamServerSubcommunityInfo.find_by_sam_server_and_subcommunity(seat_pool.sam_server, seat_pool.subcommunity) if !seat_pool.sam_server.nil?
    server_license_count_msgs = AuditMessage.find_server_license_count_messages(sssi.id) if !sssi.nil?
    render(:partial => "server_license_count_msgs", :object => server_license_count_msgs)
  end
  
  def options_for
    logger.info("entering options_for with id #{params[:id]}")
    seat_pool = SeatPool.find(params[:id])
    @seat_pool_profile = ServerCountProfile.new(seat_pool.sam_server, seat_pool.subcommunity)
    render(:partial => "license_allocation_options", :object => @seat_pool_profile)
  end
  
  def update_seat_pools
    seat_pools = SeatPool.paginate(:all, :page => params[:page], :select => "sp.*, ss.name, ss.id as server_id", :joins => "sp left outer join sam_server ss on sp.sam_server_id = ss.id",
                                     :conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ?", params[:sam_customer_id], params[:subcommunity_id]],
                                     :order => seat_pools_sort_by_param(params[:sort]),
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
    sam_server = SeatPool.find(params[:id]).sam_server
    seat_activities = paginate_seat_activities(params[:id], params[:page], params[:sort])
    render(:partial => "seat_activity_table", 
           :locals => {:seat_activity_collection => seat_activities,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :sam_server => sam_server,
                       :sam_customer_id => params[:sam_customer_id]}, :layout => false)
  end
  
  protected
  
  def load_seat_pool
    @sam_customer = SamCustomer.find(params[:sam_customer_id]) if !params[:sam_customer_id].nil?
    @seat_pool = SeatPool.find(params[:seat_pool_id]) if !params[:seat_pool_id].nil?
  end
  
  private
  
  def paginate_seat_activities(seat_pool_id, params_page, params_sort)
    SeatActivity.paginate(:select => "sa.*, u.id as user_id, u.last_name, u.first_name", :page => params_page, 
         :joins => "sa inner join users u on sa.user_id = u.id", :conditions =>  ["seat_pool_id = ?", seat_pool_id], 
         :order => seat_activity_sort_by_param(params_sort), :per_page => PAGINATION_ROWS_PER_PAGE)
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
  
  def seat_activity_sort_by_param(sort_by_arg)
    case sort_by_arg
      when "seat_activity_id" then "sa.id"
      when "starting_count" then "sa.starting_count"
      when "delta" then "sa.delta"
      when "done" then "sa.done, sa.created_at"
      when "created_at" then "sa.created_at"
      when "user" then "u.last_name"
    
      when "seat_activity_id_reverse" then "sa.id desc"
      when "starting_count_reverse" then "sa.starting_count desc"
      when "delta_reverse" then "sa.delta desc"
      when "done_reverse" then "sa.done desc, sa.created_at"
      when "created_at_reverse" then "sa.created_at desc"
      when "user_reverse" then "u.last_name desc"
      
      else "sa.id"
    end
  end

end

class ServerCountProfile

	attr_accessor :subcommunity, :server, :unallocated_count, :unregistered_count, :enrolled_on_server, :not_enrolled_on_server, :allocated_on_server,
					:allocated_on_hosted_servers, :max_allowed_on_hosted_servers, :allocated_on_local_servers, :max_allowed_on_local_servers,
					:max_allowed_via_subscription_info, :max_allowed_from_unallocated_via_available_seats, :max_allowed_from_unregistered_via_available_seats,
					:total_active_hosted_subscriptions, :max_allocatable_via_subscription_info, :product_group_allocated_on_hosted_servers
					
	def initialize(server, subcommunity)
		@allocated_on_hosted_servers = nil
		@max_allowed_on_hosted_servers = nil
		@allocated_on_local_servers = nil
		@max_allowed_on_local_servers = nil
		@max_allowed_via_subscription_info = nil
		@subcommunity = subcommunity
		product_is_hosted = (!@subcommunity.product.hosted_product.nil?)
		@server = server
		sam_customer = @server.sam_customer
		@unallocated_count = SeatPool.seat_count_unassigned(sam_customer, @subcommunity).to_i
		@unregistered_count = SeatPool.seat_count_for_server(sam_customer.unregistered_generic_server, @subcommunity).to_i
		@enrolled_on_server = server.is_unregistered_generic? ? 0 : SamServerSubcommunityInfo.enrolled_seat_count_on_server(@server, @subcommunity).to_i
		@allocated_on_server = SeatPool.seat_count_for_server( @server, @subcommunity ).to_i
		@not_enrolled_on_server = server.is_unregistered_generic? ? @allocated_on_server : SeatPool.seat_count_not_enrolled_for_license_activated_server(@server, @subcommunity).to_i
		@allocated_on_local_servers = sam_customer.local_allocated_count(@subcommunity)
		@max_allowed_on_local_servers = sam_customer.max_seats_on_local_servers(@subcommunity)
		@allocated_on_hosted_servers = sam_customer.hosted_allocated_subscription_count(@subcommunity)
		@product_group_allocated_on_hosted_servers = sam_customer.product_group_hosted_allocated_subscription_count(@subcommunity)
		@max_allowed_on_hosted_servers = sam_customer.max_seats_on_hosted_servers(@subcommunity)
		if (server.is_hosted_server?)
		  @max_allocatable_via_subscription_info = (@max_allowed_on_hosted_servers - (product_is_hosted ? @product_group_allocated_on_hosted_servers : @allocated_on_hosted_servers))
			@max_allowed_via_subscription_info = @max_allocatable_via_subscription_info + @allocated_on_server
		else
		   @max_allocatable_via_subscription_info = (@max_allowed_on_local_servers - @allocated_on_local_servers)
			@max_allowed_via_subscription_info = @max_allocatable_via_subscription_info + @allocated_on_server
		#else (this was originally for the unregistered server)
		#	@max_allowed_via_subscription_info = @unallocated_count + @allocated_on_server
		end
		@max_allowed_from_unallocated_via_available_seats = @unallocated_count + @allocated_on_server
		@max_allowed_from_unregistered_via_available_seats = @unregistered_count + @allocated_on_server
		@total_active_hosted_subscriptions = sam_customer.hosted_total_active_subscription_count(@subcommunity)
	end
	
	
	def valid_via_subscription_info?(delta)
		new_count = @allocated_on_server + delta
		return !(new_count > @max_allowed_via_subscription_info)
	end
	
end