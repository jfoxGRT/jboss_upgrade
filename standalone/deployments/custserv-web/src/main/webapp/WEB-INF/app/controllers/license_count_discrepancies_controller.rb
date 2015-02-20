require 'java'
import 'java.util.HashMap'
import 'java.lang.Character'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end

class LicenseCountDiscrepanciesController < TasksController
	
	before_filter :load_view_vars
	
	layout 'default'
	#layout "new_layout_for_tasks"
	
	def assigned
    		task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_DISCREPANCY_CODE)
    		(redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
    		@tasks = Task.find(:all, :select => "t.*, state_province.name as state_name, sc.name as sam_customer_name, ss.name as server_name, 
  								s.name as subcommunity_name, sp.seat_count as seat_pool_count, sssi.licensed_seats as server_count, u.id as target_user_id, u.first_name, u.last_name", 
                        :joins => "t inner join state_province on t.state_province_id = state_province.id
                                 inner join sam_customer sc on t.sam_customer_id = sc.id
                                 inner join task_params tp_server on (tp_server.task_id = t.id and tp_server.name = 'samServerId')
                                 inner join task_params tp_subcom on (tp_subcom.task_id = t.id and tp_subcom.name = 'subcommunityId')
                                 inner join sam_server ss on tp_server.value = ss.id
                                 inner join subcommunity s on tp_subcom.value = s.id
                                 inner join seat_pool sp on (sp.sam_server_id = ss.id and sp.subcommunity_id = s.id)
                                 inner join sam_server_community_info ssci on ssci.sam_server_id = ss.id
                                 inner join sam_server_subcommunity_info sssi on (sssi.sam_server_community_info_id = ssci.id and sssi.subcommunity_id = tp_subcom.value)
								 inner join users u on t.current_user_id = u.id", 
                       :conditions => ["t.task_type_id = ? and t.status = 'a'", task_type.id])
	end
  	
	def unassigned
  		task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_DISCREPANCY_CODE)
  		(redirect_to(:action => :index, :controller => :tasks) and return) if task_type.nil?
		conditions_clause = "t.task_type_id = ? and t.status = 'u' "
		conditions_fillins = [task_type.id]
		@sam_customer = nil
		if (!params[:sam_customer_id].nil?)
		  begin
		    @sam_customer = SamCustomer.find(params[:sam_customer_id])
		  rescue Exception => e
		    logger.info("ERROR: Could not find sam customer with id #{params[:sam_customer_id]}: #{e}")
		  end
			conditions_clause += "and t.sam_customer_id = ? "
			conditions_fillins << params[:sam_customer_id]
		end
		if (!params[:sam_server_id].nil?)
		  conditions_clause += "and ss.id = ? "
		  conditions_fillins << params[:sam_server_id]
		end
  		@tasks = Task.find(:all, :select => "t.*, state_province.name as state_name, sc.name as sam_customer_name, sc.id as sam_customer_id, ss.name as server_name, 
  								s.name as subcommunity_name, sp.seat_count as seat_pool_count, sssi.licensed_seats as server_count", 
                      :joins => "t inner join state_province on t.state_province_id = state_province.id
                                 inner join sam_customer sc on t.sam_customer_id = sc.id
                                 inner join task_params tp_server on (tp_server.task_id = t.id and tp_server.name = 'samServerId')
                                 inner join task_params tp_subcom on (tp_subcom.task_id = t.id and tp_subcom.name = 'subcommunityId')
                                 inner join sam_server ss on tp_server.value = ss.id
                                 inner join subcommunity s on tp_subcom.value = s.id
                                 inner join seat_pool sp on (sp.sam_server_id = ss.id and sp.subcommunity_id = s.id)
                                 inner join sam_server_community_info ssci on ssci.sam_server_id = ss.id
                                 inner join sam_server_subcommunity_info sssi on (sssi.sam_server_community_info_id = ssci.id and sssi.subcommunity_id = tp_subcom.value)", 
                     :conditions => [conditions_clause, conditions_fillins].flatten, :order => "t.created_at desc")
	end
  
  
  
  def edit
    get_edit_form_data  
  end
  
  
  
  def update
    get_edit_form_data
    raise LicenseCountDiscrepancyUpdateException.new(@task, flash, "All fields are required", 
                    LicenseCountDiscrepancyUpdateException::ALL_FIELDS_REQUIRED, false, @task.sam_customer) if (params[:reason].empty?)
    difference = @sssi.licensed_seats - @seat_pool.seat_count
    puts "params[:balance_option] = #{params[:balance_option]}"
	  entitlement_service = SC.getBean("entitlementService")
	  seat_pool_service = SC.getBean("seatPoolService")
    begin
      SamCustomer.transaction do 
        if (difference > 0)
            # if "Add to Total Licenses"
            if (params[:balance_option] == "1")
              # set licensing status to pending
				#@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_DISABLED.to_s)
              # create virtual entitlement
			  # create virtual entitlement
				entitlement_service.applyNewVirtualEntitlement(@subcommunity.id, @sam_customer.id, difference, current_user.id, "LCDTR", @task.id)
              #entitlement = Entitlement.create_virtual_entitlement(@sam_customer, @subcommunity, difference)
              #EntitlementAudit.create(:entitlement => entitlement, :annotation => params[:reason], :user => current_user)
			  seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, @sam_server.id, difference, "RLCDT") 
              #@seat_pool.seat_count += difference
              #@seat_pool.save
              # reenable licensing status
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_ENABLED.to_s)
            # otherwise, if "Deduct from Unallocated Pool"..
            elsif (params[:balance_option] == "2")
              # get the unallocated pool for this subcommunity
              unallocated_pool = SeatPool.obtain_seat_pool(@sam_customer, @subcommunity, nil)
			  raise LicenseCountDiscrepancyUpdateException.new(@task, flash, "There are not enough unallocated licenses to take away", 
						LicenseCountDiscrepancyUpdateException::INVALID_OPERATION, false, @task.sam_customer) if difference > unallocated_pool.seat_count
              # set licensing status to pending
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_DISABLED.to_s)
			  # adjust the pools accordingly
				seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, nil, (difference * -1), "RLCDT")
				seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, @sam_server.id, difference, "RLCDT")
              #unallocated_pool.seat_count -= difference
              #@seat_pool.seat_count += difference
              #unallocated_pool.save
              #@seat_pool.save
              # reenable licensing status
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_ENABLED.to_s)
            else
              raise LicenseCountDiscrepancyUpdateException.new(@task, flash, "You must select an option", 
                        LicenseCountDiscrepancyUpdateException::OPTION_NOT_SELECTED, false, @task.sam_customer)
            end
        #otherwise, difference < 0
        else
          logger.info("difference is #{difference}")
          logger.info("seat pool count is #{@seat_pool.seat_count}")
			raise LicenseCountDiscrepancyUpdateException.new(@task, flash, "There are not enough licenses to take away", 
						LicenseCountDiscrepancyUpdateException::INVALID_OPERATION, false, @task.sam_customer) if ((difference * -1) > @seat_pool.seat_count)
            # if "Subtract from Total Licenses"
            if (params[:balance_option] == "1")
              # set licensing status to pending
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_DISABLED.to_s)
              # create virtual entitlement
			        entitlement_service.applyNewVirtualEntitlement(@subcommunity.id, @sam_customer.id, difference, current_user.id, "LCDTR", @task.id)
              #entitlement = Entitlement.create_virtual_entitlement(@sam_customer, @subcommunity, difference)
              #EntitlementAudit.create(:entitlement => entitlement, :annotation => params[:reason], :user => current_user)
              # adjust the count in the seat pool that is causing this discrepancy
			        seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, @sam_server.id, difference, "RLCDT")
              #@seat_pool.seat_count += difference
              #@seat_pool.save
              # reenable licensing status
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_ENABLED.to_s)
            # otherwise, "Credit Unallocated Pool"
            elsif (params[:balance_option] == "2")
              # obtain the unallocated pool
              unallocated_pool = SeatPool.obtain_seat_pool(@sam_customer, @subcommunity, nil)
              # set licensing status to pending
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_DISABLED.to_s)
			        seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, nil, (difference * -1), "RLCDT")
			        seat_pool_service.adjustSeatCount(@sam_customer.id, @subcommunity.id, @sam_server.id, difference, "RLCDT")
              #unallocated_pool.seat_count += (difference * -1)
              #@seat_pool.seat_count += difference
              #unallocated_pool.save
              #@seat_pool.save
              # reenable licensing status
              #@sam_customer.update_attribute(:licensing_status, SamCustomer.MANAGER_ENABLED.to_s)
            else
              raise LicenseCountDiscrepancyUpdateException.new(@task, flash, "You must select an option", 
                        LicenseCountDiscrepancyUpdateException::OPTION_NOT_SELECTED, false, @task.sam_customer)
            end
        end
		    close_task(@task)
        flash[:notice] = "Successfully resolved discrepancy for #{@subcommunity.name} on #{@sam_server.name}"
        flash[:msg_type] = "info"
        redirect_to(unassigned_license_count_discrepancies_path(:sam_customer_id => @sam_customer.id))
      end
    end
  rescue Exception => e
      logger.info(e.to_s)
      flash[:notice] = "Error occurred while resolving license count discrepancy: #{e}.  No changes were applied.  Please note the task ID and inform a SAMC administrator." if flash[:notice].nil?
      redirect_to(edit_license_count_discrepancy_path(:id => @task.id, :reason => params[:reason], :balance_option => params[:balance_option]))
  end
  
  
  #####################
  # PROTECTED METHODS #
  #####################
  
  protected
  
  class LicenseCountDiscrepancyUpdateException < UpdateException
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
    @task.task_params.each do |tp|
        case tp.name
          when "samServerId" then @sam_server = SamServer.find(tp.value)
          when "subcommunityId" then @subcommunity = Subcommunity.find(tp.value)
        end
    end
    @unallocated_pool = SeatPool.find_seat_pool(@sam_customer, @subcommunity, nil)
    @seat_pool = SeatPool.obtain_seat_pool(@sam_customer, @subcommunity, @sam_server)
    @sssi = SamServerSubcommunityInfo.find_by_sam_server_and_subcommunity(@sam_server, @subcommunity)
  end
  
  def load_view_vars
    @crappy_modal_support = true
  end
  
	
end
