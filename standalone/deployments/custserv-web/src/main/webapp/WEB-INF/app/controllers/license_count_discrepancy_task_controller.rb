class LicenseCountDiscrepancyTaskController < TasksController
  
  layout 'cs_layout'
  
  def new
    puts "params: #{params.to_yaml}"
    @task = Task.find(params[:task_id])
    @subcommunity = Subcommunity.find(params[:subcommunity_id])
    @annotation = params[:annotation]
    @sam_customer = @task.sam_customer
    @subcommunity_scale = @sam_customer.build_seat_count_profile(@subcommunity.id, @task.created_at)
    @entitlement_audits = EntitlementAudit.get_current_by_sam_customer_id_and_product_id(@sam_customer.id, @subcommunity.product.id)
  end
  
  def create
    
    @task = Task.find(params[:task_id])
    @seat_pool_count = params[:pool_count]
    @sssi_count = params[:server_count]
    
    puts "params: #{params.to_yaml}"
    @annotation = params[:annotation]
    @delta = params[:delta]
    invalid_data = false
    
    if (@annotation.strip.empty?)
      flash[:notice] = "You must enter notes about your license count change."
      invalid_data = true
    end
    
    if (@delta.to_i == 0)
      flash[:notice] = "You must enter a non-zero license count."
      invalid_data = true
    end
    
    (redirect_to(:action => :new, :task_id => params[:task_id], :subcommunity_id => params[:subcommunity_id], :annotation => params[:annotation]) and return) if (invalid_data)
    
    subcom = Subcommunity.find(params[:subcommunity_id])
    sam_customer = SamCustomer.find(params[:sam_customer_id])
    
    @subcommunity_scale = sam_customer.build_seat_count_profile(subcom.id, @task.created_at)
    unallocated_sp = SeatPool.obtain_seat_pool(sam_customer, subcom, nil)

    discrepancy_count = @subcommunity_scale.server_count - @subcommunity_scale.allocated_pool_count
    delta_num = @delta.to_i
    #difference_in_db = sssi_count - seat_pool_count
    
    if (@seat_pool_count.to_i != @subcommunity_scale.allocated_pool_count)
      flash[:notice] = "The entitlement license count has recently been changed.  Please try again."
      redirect_to(:controller => :tasks, :action => :edit, :id => @task.id)
      return
    elsif ((delta_num + @subcommunity_scale.virtual_entitlement_count) > discrepancy_count)
      flash[:notice] = "Your license count change is too large in quantity"
      invalid_data = true
    end
    
    # if there are now new pending reallocations for the subcommunity, fail the request
    if (!@subcommunity_scale.seat_pool_pending_reallocations.nil?)
      flash[:notice] = "There are currently new pending reallocations for this product.  Please try again later."
      invalid_data = true
    end
    
    (redirect_to(:action => :new, :task_id => params[:task_id], :subcommunity_id => params[:subcommunity_id], :annotation => params[:annotation]) and return) if (invalid_data)
    
    # find the seat pool that we're adding to or subtracting from
    # if the balancing operation requires taking seats AWAY from the unallocated pool, then make sure we have enough to take away
    # otherwise, fail the operation
    if (delta_num < 0 && unallocated_sp.seat_count < (delta_num.abs))
      flash[:notice] = "Sorry, there are currently not enough unallocated seats to accommodate your request"
      redirect_to(:action => :new, :task_id => params[:task_id], :subcommunity_id => params[:subcommunity_id], :annotation => params[:annotation])
      return
    end
    
    begin
      Entitlement.transaction do
      
        # first create the virtual entitlement
        virt_entitlement = Entitlement.create_virtual_entitlement(sam_customer, subcom, delta_num)
        
        # apply the seat delta
        unallocated_sp.seat_count += delta_num
        unallocated_sp.save!
        
        # mark a record in the audit table
        EntitlementAudit.create(:entitlement => virt_entitlement, :annotation => @annotation, :initial_conversion => false, :user => current_user)
        
        flash[:notice] = "" + @delta + " " + subcom.name + " seat(s) applied successfully"
      end
    rescue
      flash[:notice] = "Your request could not be processed.  Please try again."
    end
    
    redirect_to(:controller => :tasks, :action => :edit, :id => @task.id)
  end
  
  def show
    
  end
  
end