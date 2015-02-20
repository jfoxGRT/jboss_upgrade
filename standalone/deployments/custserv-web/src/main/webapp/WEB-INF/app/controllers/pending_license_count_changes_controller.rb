require 'java'
import 'java.util.HashMap'
import 'java.lang.Character'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
class PendingLicenseCountChangesController < TasksController
	
	before_filter :load_view_vars
	
	#layout "new_layout_for_tasks"
	layout "default"
	#layout "default_with_docking"
	
	def assigned
    		task_type = TaskType.find_by_code(TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE)
    		(redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
    		@tasks = Task.find(:all, :select => "t.*, sp.name as state_name, sc.name as sam_customer_name, sc.id as sam_customer_id, tp_server.value as server_name, 
    								tp_subcommunity.value as subcommunity_name, tp_delta.value as delta, u.id as target_user_id, u.first_name, u.last_name", 
                        :joins => "t inner join state_province sp on t.state_province_id = sp.id 
                                   inner join sam_customer sc on t.sam_customer_id = sc.id
                                   left join task_params tp_server on (tp_server.task_id = t.id and tp_server.name = 'serverName')
                                   inner join task_params tp_subcommunity on (tp_subcommunity.task_id = t.id and tp_subcommunity.name = 'subcommunityName')
                                   inner join task_params tp_delta on (tp_delta.task_id = t.id and tp_delta.name = 'delta')
                                   inner join users u on t.current_user_id = u.id", 
                       :conditions => ["t.task_type_id = ? and t.status = 'a'", task_type.id])
  end
  	
    
    
	def unassigned 
		#Look for the from_landscape param, and set it in the session
		if (!params[:from_landscape].nil? && params[:from_landscape] == "y")
			session[:from_landscape_page] = 'true'
		end
	
		task_type = TaskType.find_by_code(TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE)
		(redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
		if (!params[:sam_customer_id].nil? || !params[:ucn].nil?)
		  conditions_clause = "t.task_type_id = ? and t.status = 'u' "
  		conditions_fillins = [task_type.id]
  		joins_clause = "t inner join state_province sp on t.state_province_id = sp.id inner join sam_customer sc on t.sam_customer_id = sc.id "
  		joins_clause += "left join task_params tp_subcommunity on (tp_subcommunity.task_id = t.id and tp_subcommunity.name = 'subcommunityName') "
  		joins_clause += "left join task_params tp_clp on (tp_clp.task_id = t.id and tp_clp.name = 'conversionLicensePoolId') "
  		joins_clause += "left join conversion_licenses cl on cl.id = tp_clp.value "
  		joins_clause += "left join product cp on cl.product_id = cp.id "
  		joins_clause += "inner join task_params tp_delta on (tp_delta.task_id = t.id and tp_delta.name = 'delta') "
  		if (!params[:product_id].nil?)
  			product = Product.find_by_id_value(params[:product_id])
  			if (!product.nil?)
  				subcommunity = product.subcommunity
  				if (!subcommunity.nil?)
  					joins_clause += "inner join task_params tp_subcommunityid on (tp_subcommunityid.task_id = t.id and tp_subcommunityid.name = 'subcommunityId' and tp_subcommunityid.value = '#{subcommunity.id}') "
  				else
  				end
  			end
  		end
  		@sam_customer = nil
  		if (!params[:sam_customer_id].nil?)
  			conditions_clause += "and t.sam_customer_id = ? "
  			conditions_fillins << params[:sam_customer_id]
  			begin
  			  @sam_customer = SamCustomer.find(params[:sam_customer_id])
  			rescue Exception => e
  			  logger.info("ERROR:  Couldn't find sam customer with id #{params[:sam_customer_id]}: #{e}")
  			end
  		elsif (!params[:ucn].nil?)
  			customer = Customer.find_by_ucn(params[:ucn])
  			if (!customer.nil?)
  				@sam_customer = customer.org.sam_customer
  				if (!sam_customer.nil?)
  					conditions_clause += "and t.sam_customer_id = ? "
  					conditions_fillins << sam_customer.id
  				end
  			end
  		end
  		joins_clause += "left join task_params tp_server on (tp_server.task_id = t.id and tp_server.name = 'serverName') "
  		joins_clause += "left join task_params tp_reason on (tp_reason.task_id = t.id and tp_reason.name = 'reason')"
  		joins_clause += "left join task_params tp_seatpoolid on (tp_seatpoolid.task_id = t.id and tp_seatpoolid.name = 'seatPoolId')"
  		joins_clause += "left join seat_pool spool on tp_seatpoolid.value = spool.id"
  		  
  		@tasks = Task.find(:all, :select => "t.*, sp.name as state_name, sc.name as sam_customer_name, tp_server.value as server_name, 
    								tp_subcommunity.value as subcommunity_name, tp_delta.value as delta, tp_reason.value as reason_code, spool.seat_count, cp.description as conversion_product_name, cl.unconverted_count", 
  							:joins => joins_clause,
  							:conditions => [conditions_clause, conditions_fillins].flatten, :order => "t.priority desc")
  		logger.info("da tasks: #{@tasks.to_yaml}")
  		redirect_to(unassigned_pending_license_count_changes_path) if @tasks.length == 0
  	else
  	  @open_plcc_counts = Task.find(:all, :select => "sc.id as sam_customer_id, sc.name, sp.code, c.ucn, count(t.id) as open_task_count",
  	                                :joins => "t inner join task_types tt on t.task_type_id = tt.id 
  	                                            inner join sam_customer sc on t.sam_customer_id = sc.id
  	                                            inner join org on sc.root_org_id = org.id
  	                                            inner join customer c on org.customer_id = c.id
  	                                            inner join state_province sp on t.state_province_id = sp.id",
  	                                :conditions => ["tt.code = ? and t.status != 'c'", TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE], :group => "sc.id", :order => "sc.name")
  	end
  end
  
  
  
  def edit
    gather_plcc_data(@task)
  end
  
  
  
  def update
    gather_plcc_data(@task)
    raise PendingLicenseCountChangeUpdateException.new(@task, flash, "Applying the pending license delta would currently result in a negative license count.  Please ask the customer to free up licenses.", 
                    PendingLicenseCountChangeUpdateException::NEGATIVE_LICENSE_COUNT, false, @task.sam_customer) if ((@current_license_count + @delta) < 0)
    raise PendingLicenseCountChangeUpdateException.new(@task, flash, "The customer's License Manager is currently disabled.  Cannot adjust license counts.", 
                    PendingLicenseCountChangeUpdateException::LICENSE_MANAGER_DISABLED, false, @task.sam_customer) if (@sam_customer.licensing_status == SamCustomer.MANAGER_DISABLED)
	  entitlement_service = SC.getBean("entitlementService")
	  seat_pool_service = SC.getBean("seatPoolService")
	  if (@conversion_license_pool.nil?)
  	  seat_pool_service.adjustSeatCount(@sam_customer.id, @seat_pool.subcommunity.id, (@seat_pool.sam_server.nil?) ? nil : @seat_pool.sam_server.id, @delta, @reason)
  	else
  	  entitlement_service.adjustConversionLicensePoolCountForTaskResolution(@conversion_license_pool.id, @delta)
  	end
  	#if (reason == "LSE")
  	#	message_sender = SC.getBean("messageSender")
  	#	message_sender.sendDecommissionedSeatCount(@sam_customer.id, @subcommunity.id, @delta * -1)
  	#end
    #@seat_pool.seat_count += @delta
    #@seat_pool.save
    close_task(@task)
    flash[:notice] = "Successfully applied license count change"
    flash[:msg_type] = "info"
    redirect_to(unassigned_pending_license_count_changes_path(:sam_customer_id => @sam_customer.id))
  rescue Exception => e
    logger.info("Experienced error during Pending License Count change update: #{e.to_s}")
    if flash[:notice].nil?
      flash[:notice] = "An error occurred while closing this task: #{e}"
      flash[:notice] += "(exception code = #{e.exception_code})" if e.instance_of?(TaskException)
      flash[:notice] += "&nbsp;&nbsp;Please contact an SAMC Administrator"
    end
    redirect_to((!e.instance_of?(TaskException) || e.redirect.nil?) ? edit_pending_license_count_change_path(@task.id) : e.redirect)
  end
  
  
  
  private
  
  def gather_plcc_data(task)
    @sam_customer = task.sam_customer
    @org_details = Org.find_summary_details(@sam_customer.root_org.id)
    tparams = task.task_params
    @sam_server_name = nil
    @product_name = nil
    @conversion_license_pool = nil
	  @reason = "U"
    seat_pool_id = 0
    conversion_license_pool_id = 0
    entitlement_id = 0
    tparams.each do |tp|
      case tp.name
        when "oldLicenseCount" then @current_license_count = tp.value.to_i
        when "delta" then @delta = tp.value.to_i
        when "serverName" then @sam_server_name = tp.value
        when "subcommunityName" then @product_name = tp.value
        when "conversionLicensePoolId" then conversion_license_pool_id = tp.value.to_i
        when "entitlementId" then entitlement_id = tp.value.to_i
        when "seatPoolId" then seat_pool_id = tp.value.to_i
		    when "reason" then @reason = tp.value
      end
    end
    if seat_pool_id != 0
      @seat_pool = SeatPool.find(seat_pool_id)
      @current_license_count = @seat_pool.seat_count
    end
    if conversion_license_pool_id != 0
      @conversion_license_pool = ConversionLicense.find(conversion_license_pool_id)
      @current_license_count = @conversion_license_pool.unconverted_count
      @product_name = @conversion_license_pool.product.description
    end 
    @entitlement = Entitlement.find(entitlement_id) if entitlement_id != 0
  end
  
  
  class PendingLicenseCountChangeUpdateException < UpdateException
    UNKNOWN = 0
    NEGATIVE_LICENSE_COUNT = 1
    LICENSE_MANAGER_DISABLED = 2
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, sam_customer, redirect)    
    end
  end
  
  def load_view_vars
    @crappy_modal_support = true
  end
  
  
	
end
