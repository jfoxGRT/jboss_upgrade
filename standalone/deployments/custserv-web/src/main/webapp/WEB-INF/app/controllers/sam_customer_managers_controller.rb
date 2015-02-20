require 'sam_customer_manager/defaultDriver'

class SamCustomerManagersController < SamCustomersController
  
  layout 'new_layout_with_jeff_stuff'
  
  def index
  end

  def edit
    case (params[:id])
      when SamCustomer.LICENSE_MANAGER then
        begin
          @manager = LICENSE_MANAGER_TERM
          (@license_count_comparisons, @resyncable = @sam_customer.build_seat_count_profile(nil, nil)) if (@sam_customer.sam_servers.length > 0)
          render(:template => "sam_customer_managers/edit_lm")
        end  
      when SamCustomer.UPDATE_MANAGER then
        begin
          @manager = UPDATE_MANAGER_TERM
          render(:template => "sam_customer_managers/edit_sum")
        end
      end
  end
  
  def activate
    LicensingActivation.create(:sam_customer => @sam_customer, :user => current_user)
    # Invoke the Sam Customer Manager to finish the work.
    sam_customer_manager = SamCustomerManagerPortType.new( SAM_CUSTOMER_MANAGER_URL )
    param = SyncLicenseCountsToServers.new
    param.samCustomerId = @sam_customer.id
    
    sam_customer_manager.syncLicenseCountsToServers( param ).out
    flash[:notice] = (@sam_customer.name + " is in the process of being activated for SC-Licensing")
    redirect_to(sam_customer_path(@sam_customer.id))
  end
  
  def deactivate
    puts "params: #{params.to_yaml}"
    case (params[:id])
      when SamCustomer.LICENSE_MANAGER then deactivate_license_manager(@sam_customer)
      when SamCustomer.UPDATE_MANAGER then deactivate_update_manager(@sam_customer)
    end
    redirect_to(sam_customer_path(@sam_customer))
  end
  
  def reset
    puts "params: #{params.to_yaml}"
    case (params[:id])
      when SamCustomer.LICENSE_MANAGER then reset_license_manager(@sam_customer)
      when SamCustomer.UPDATE_MANAGER then reset_update_manager(@sam_customer)
    end
    redirect_to(sam_customer_path(@sam_customer))
  end
  
  private
  
  def reset_license_manager(sam_customer)
    LicensingActivation.create(:sam_customer => sam_customer, :user => current_user)
    # Invoke the Sam Customer Manager to finish the work.
    sam_customer_manager = SamCustomerManagerPortType.new( SAM_CUSTOMER_MANAGER_URL )
    param = SyncLicenseCountsToServers.new
    param.samCustomerId = sam_customer.id
    
    sam_customer_manager.syncLicenseCountsToServers( param ).out
    flash[:notice] = (sam_customer.name + " is in the process of being re-synced")
  end
  
  def deactivate_license_manager(sam_customer)
    
    begin
      SamCustomer.transaction do
        
        # Kill the seat activity records and server pools
        seat_pools = SeatPool.find(:all, :select => "sp.*, sa.id as seat_activity_id", :joins => "sp left join seat_activity sa on sa.seat_pool_id = sp.id", 
                     :conditions => ["sp.sam_customer_id = ? and sp.sam_server_id is not null", sam_customer.id])
        seat_pools.each do |sp|
          SeatActivity.delete(sp.seat_activity_id) if !sp.seat_activity_id.nil?
          SeatPool.delete(sp.id)
        end
        
        # Kill the virtual entitlements
        virtual_entitlements = Entitlement.find(:all, :select => "e.*, ea.id as entitlement_audit_id", :joins => "e inner join entitlement_audit ea on ea.entitlement_id = e.id",
                               :conditions => ["sc_entitlement_type_id = ? and sam_customer_id = ?", ScEntitlementType.find_by_code(ScEntitlementType.VIRTUAL_CODE).id, sam_customer.id])
        virtual_entitlements.each do |ve|
          EntitlementAudit.delete(ve.entitlement_audit_id) if ve.entitlement_audit_id
          Entitlement.delete(ve.id)
        end
        
        # Convert all the SAM Customer's entitlements to Pre-SAMC
        Entitlement.update_all("sc_entitlement_type_id = #{ScEntitlementType.find_by_code(ScEntitlementType.LEGACY_CODE).id}", "sam_customer_id = #{sam_customer.id}")
        
        # Clear the LM flag and date
        sam_customer.sc_licensing_activated = nil
        sam_customer.licensing_status = SamCustomer.MANAGER_NOT_ACTIVATED
        sam_customer.save!
        
        #TODO: If we ever start applying this functionality to non-fake sam customers, then notification to TMS needs to be sent here.
        
        flash[:notice] = "Successfully deactivated License Manager for #{@sam_customer.name}"
        flash[:msg_type] = "info"
        
      end
    rescue Exception => e
      flash[:notice] = "Could not deactivate License Manager for #{@sam_customer.name} at this time. If this problem persists, please contact a SAMC administrator."
      logger.info("ERROR: #{e}")
    end
    
  end
  
  
  def deactivate_update_manager(sam_customer)
    
    begin
      SamCustomer.transaction do
        
        # Clear the UM flag and date
        sam_customer.update_manager_activated = nil
        sam_customer.update_manager_status = SamCustomer.MANAGER_NOT_ACTIVATED
        sam_customer.save!
        
        #TODO: If we ever start applying this functionality to non-fake sam customers, then notification to TMS needs to be sent here.
         
      end
    rescue
      flash[:notice] = "Could not deactivate Update Manager for #{@sam_customer.name} at this time.  If this problem persists, please contact a SAMC administrator."
    end
  end
  
end
