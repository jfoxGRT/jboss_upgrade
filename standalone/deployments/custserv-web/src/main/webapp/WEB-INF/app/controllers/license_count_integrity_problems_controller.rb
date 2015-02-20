require 'java'
import 'java.util.HashMap'
import 'java.lang.Character'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
class LicenseCountIntegrityProblemsController < TasksController
  
  before_filter :load_view_vars
  
  layout "default"
  
  def assigned
    		task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_INTEGRITY_PROBLEM_CODE)
    		(redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
    		@tasks = Task.find(:all, :select => "t.*, state_province.name as state_name, sc.name as sam_customer_name, 
  								s.name as subcommunity_name, tp_entcount.value as entitlement_count, tp_poolcount.value as seat_pool_count,
								u.id as target_user_id, u.first_name, u.last_name", 
                        :joins => "t inner join state_province on t.state_province_id = state_province.id
                                 inner join sam_customer sc on t.sam_customer_id = sc.id
                                 inner join task_params tp_entcount on (tp_entcount.task_id = t.id and tp_entcount.name = 'entitlementCount')
								 inner join task_params tp_poolcount on (tp_poolcount.task_id = t.id and tp_poolcount.name = 'seatPoolCount')
                                 inner join task_params tp_subcom on (tp_subcom.task_id = t.id and tp_subcom.name = 'subcommunityId')
                                 inner join subcommunity s on tp_subcom.value = s.id
								 inner join users u on t.current_user_id = u.id", 
                       :conditions => ["t.task_type_id = ? and t.status = 'a'", task_type.id])
  end
  
  def unassigned
  		task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_INTEGRITY_PROBLEM_CODE)
  		(redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
		conditions_clause = "t.task_type_id = ? and t.status = 'u' "
		conditions_fillins = [task_type.id]
		if (!params[:sam_customer_id].nil?)
			conditions_clause += "and t.sam_customer_id = ? "
			conditions_fillins << params[:sam_customer_id]
		end
  		@tasks = Task.find(:all, :select => "t.*, state_province.name as state_name, sc.name as sam_customer_name, 
  								s.name as subcommunity_name", 
                      :joins => "t inner join state_province on t.state_province_id = state_province.id
                                 inner join sam_customer sc on t.sam_customer_id = sc.id
                                 left join task_params tp_subcom on (tp_subcom.task_id = t.id and tp_subcom.name = 'subcommunityId')
                                 left join subcommunity s on tp_subcom.value = s.id
                                 left join product p on s.product_id = p.id", 
                     :conditions => [conditions_clause, conditions_fillins].flatten, :group => "t.id", :order => "t.priority desc")
	end
	
	def edit
		get_edit_form_data  
	end
  
  
  
  def update
    get_edit_form_data
    raise LicenseCountIntegrityProblemUpdateException.new(@task, flash, "All fields are required", 
                    LicenseCountIntegrityProblemUpdateException::ALL_FIELDS_REQUIRED, false, @task.sam_customer) if (params[:reason].empty?)
    # calculate the difference that needs to be rectified
    puts "params[:balance_option] = #{params[:balance_option]}"
    begin
      SamCustomer.transaction do 
		    entitlement_service = SC.getBean("entitlementService")
		    seat_pool_service = SC.getBean("seatPoolService")
    		# if "Match Entitlement Count to Seat Pool Count"
    		if (params[:balance_option] == "1")
    		  # create virtual entitlement
    		  entitlement_service.applyNewVirtualEntitlement(@subcommunity.id, @sam_customer.id, @difference, current_user.id, "LCIPTR", @task.id)
    		  #@seat_pool.seat_count += difference
    		  #@seat_pool.save
    		# otherwise, if "Match Seat Pool Count to Entitlement Count"..
    		elsif (params[:balance_option] == "2")
    		  # get the unallocated pool for this subcommunity
    		  unallocated_pool = SeatPool.obtain_seat_pool(@sam_customer, @subcommunity, nil)
    		  raise LicenseCountIntegrityProblemUpdateException.new(@task, flash, "There are not enough unallocated licenses to take away", 
    					LicenseCountIntegrityProblemUpdateException::INVALID_OPERATION, false, @task.sam_customer) if @difference > unallocated_pool.seat_count
    	      # adjust the unallocated seat pool accordingly
    		  seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, nil, (@difference * -1), "RLCIPT")
    		else
    		  raise LicenseCountIntegrityProblemUpdateException.new(@task, flash, "You must select an option", 
    					LicenseCountIntegrityProblemUpdateException::OPTION_NOT_SELECTED, false, @task.sam_customer)
    		end
    		close_task(@task, @sam_customer, params[:reason])
        flash[:notice] = "Successfully resolved license count integrity problem for #{@subcommunity.name} at #{@sam_customer.name}"
        flash[:msg_type] = "info"
        redirect_to(unassigned_license_count_integrity_problems_path)
      end
    end
  rescue Exception => e
      logger.info(e.to_s)
      flash[:notice] = "Error occurred while resolving license count integrity problem.  No changes were applied.  Please note the task ID and inform a SAMC administrator: #{e}" if flash[:notice].nil?
      redirect_to(edit_license_count_integrity_problem_path(:id => @task.id, :reason => params[:reason], :balance_option => params[:balance_option]))
  end
  
  
  #####################
  # PROTECTED METHODS #
  #####################
  
  protected
  
  class LicenseCountIntegrityProblemUpdateException < UpdateException
    UNKNOWN = 0
    ALL_FIELDS_REQUIRED = 1
    NOT_ENOUGH_SEATS_AVAILABLE = 2
    OPTION_NOT_SELECTED = 3
    NO_SEAT_POOL = 4
	INVALID_OPERATION = 5
    def initialize(task, flash = nil, msg = nil, exception_code = UNKNOWN, task_obsolete = false, sam_customer = nil, redirect = nil)
      super(task, flash, msg, exception_code, task_obsolete, sam_customer, redirect)
    end
  end
  
  ###################
  # PRIVATE METHODS #
  ###################
  
  private
  
  def get_edit_form_data
    @balance_option = params[:balance_option]
    puts "Jeff's reason= #{params[:reason]}"
    @reason = params[:reason]
    @sam_customer = @task.sam_customer
    @org_details = Org.find_summary_details(@sam_customer.root_org.id)
	  @entitlement_count = 0
	  @seat_pool_count = 0
	  @subcommunity = nil
	  @unallocated_count = 0
    @task.task_params.each do |tp|
		  case tp.name
  			when "subcommunityId" then @subcommunity = Subcommunity.find(tp.value)
  		end
	  end
    unallocated_pool = SeatPool.find_seat_pool(@sam_customer, @subcommunity, nil)
		@unallocated_count = unallocated_pool.seat_count if !unallocated_pool.nil?
		@virtual_count = @sam_customer.virtual_entitlement_count(@subcommunity.id, nil)
		@seat_pool_count = @sam_customer.seat_pool_count(@subcommunity.id)
		@entitlement_count = @sam_customer.entitlement_count(@subcommunity.id)
		@net_plcc_count = @sam_customer.net_plcc_count(@subcommunity.id)
		@conversion_adjustment_count = @sam_customer.conversion_adjustment_count(@subcommunity)
		@difference = (@seat_pool_count + @net_plcc_count + @conversion_adjustment_count) - @entitlement_count
  end
  
  def load_view_vars
    @crappy_modal_support = true
  end
  
end
