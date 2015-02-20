require 'sam_customer_manager/defaultDriver'

class SamCustomerController < ApplicationController

include SamCustomerManager

layout 'default'

def activate_sc_licensing

  @sam_customer = SamCustomer.find(params[:id])

  # Check to make sure that we're both in balance and that there are no new conversations pending.
  subcom_scales, licensing_activation_enabled = form_subcommunity_scales(@sam_customer)
  if(!licensing_activation_enabled)
    flash[:notice] = "Unable to synchronize license counts with servers.  The seat counts are no longer in balance."
    redirect_to(:action => :sam_customer_details, :id => params[:id])
    return
  end
  subcom_scales.each do |ss|
    if(!ss.seat_pool_pending_reallocations.nil?)
      flash[:notice] = "Unable to synchronize license counts with servers.  There are currently seat reallocations pending."
      redirect_to(:action => :sam_customer_details, :id => params[:id])
      return
    end
  end
  
  #TODO: This stuff should really belong in the SamCustomerManager.
  
  licensing_activation_record = LicensingActivation.create(:sam_customer => @sam_customer, :user => current_user)
  entitlement_audit_records = EntitlementAudit.find(:all, :select => "entitlement_audit.*", :joins => "inner join entitlement on entitlement_audit.entitlement_id = entitlement.id", 
                                                    :conditions => ["entitlement_audit.licensing_activation_id is null and entitlement.sam_customer_id = ?", @sam_customer.id])
  entitlement_audit_records.each do |ear|
    ear.licensing_activation = licensing_activation_record
    puts ear.class
    ear.save!
  end
  
  # Invoke the Sam Customer Manager to finish the work.
  sam_customer_manager = SamCustomerManagerPortType.new( SAM_CUSTOMER_MANAGER_URL )
  param = SyncLicenseCountsToServers.new
  param.samCustomerId = params[:id]
  sam_customer_manager.syncLicenseCountsToServers( param ).out
  
end

def weigh_subcommunity
  @sam_customer = SamCustomer.find(params[:sam_customer_id])
  @subcommunity = Subcommunity.find(params[:subcommunity_id])
  @seat_pool_count = params[:seat_pool_count]
  @sssi_count = params[:sssi_count]
end

def balance

  @sam_customer = SamCustomer.find(params[:sam_customer_id])
  @subcommunity = Subcommunity.find(params[:subcommunity_id])
  @seat_pool_count = params[:seat_pool_count]
  @sssi_count = params[:sssi_count]
  
  if request.post?
  
    @annotation = params[:annotation]
    @delta = params[:delta]
    invalid_data = false
    
    if (@annotation.nil? || @annotation.strip.empty?)
      flash[:notice] = "You must enter notes about your license count change."
      invalid_data = true
    end
    
    if (@delta.nil? || @delta.to_i == 0)
      flash[:notice] = "You must enter a non-zero license count."
      invalid_data = true
    end
  
    return if (invalid_data)
    
    subcom = Subcommunity.find(params[:subcommunity_id])
    sam_customer = SamCustomer.find(params[:sam_customer_id])  
    
    subcom_scale = form_subcommunity_scale(sam_customer, subcom)
    sssi_count = subcom_scale.total_sssi_count.to_i
    seat_pool_count = subcom_scale.total_seat_pool_count.to_i
    delta_num = @delta.to_i
    difference_in_db = sssi_count - seat_pool_count
    new_seat_pool_count = seat_pool_count + delta_num
    
    if (@seat_pool_count.to_i != seat_pool_count)
      flash[:notice] = "The entitlement license count has recently been changed.  Please try again."
      redirect_to(:action => :sam_customer_details, :id => params[:sam_customer_id])
      return
    elsif ((new_seat_pool_count > sssi_count) || (new_seat_pool_count < 0))
      flash[:notice] = "Your license count change is too large in quantity"
      invalid_data = true
    end
    
    # if there are now new pending reallocations for the subcommunity, fail the request
    if (!subcom_scale.seat_pool_pending_reallocations.nil?)
      flash[:notice] = "There are currently new pending reallocations for this product.  Please try again later."
      invalid_data = true
    end
    
    return if (invalid_data)
    
    # find the seat pool that we're adding to or subtracting from
    sp = SeatPool.obtain_seat_pool(sam_customer, subcom, nil)
    # if the balancing operation requires taking seats AWAY from the unallocated pool, then make sure we have enough to take away
    # otherwise, fail the operation
    if (delta_num < 0 && sp.seat_count < (delta_num.abs))
      flash[:notice] = "Sorry, there are currently not enough unallocated seats to accommodate your request"
      return
    end
    
    begin
      Entitlement.transaction do
      
        # first create the virtual entitlement
        virt_entitlement = Entitlement.create_virtual_entitlement(sam_customer, subcom, delta_num)
        
        # apply the seat delta
        sp.seat_count += delta_num
        sp.save!
        
        # mark a record in the audit table
        initial_conv = sam_customer.sc_licensing_activated.nil?
        EntitlementAudit.create(:entitlement => virt_entitlement, :annotation => @annotation, :initial_conversion => initial_conv, :user => current_user)
        
        flash[:notice] = "" + @delta + " " + subcom.name + " seat(s) applied successfully"
      end
    rescue
      flash[:notice] = "Your request could not be processed.  Please try again."
    end
    
    redirect_to(:action => :sam_customer_details, :id => params[:sam_customer_id])
  end
end

def server_details
  @server = SamServer.find(params[:id])
end



#################
# AJAX ROUTINES #
#################

def update_entitlement_table
  @entitlements = Entitlement.paginate(:page => params[:page],
         :select => "entitlement.*",
         :joins => "inner join sc_entitlement_type on entitlement.sc_entitlement_type_id = sc_entitlement_type.id inner join product on entitlement.product_id = product.id",
         :conditions =>  ["sam_customer_id = ?", params[:id]], :order => entitlement_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
  render(:partial => "entitlement_info", 
         :locals => {:entitlement_collection => @entitlements,
                     :status_indicator => params[:status_indicator],
                     :update_element => params[:update_element]})
end

def update_server_table
  @servers = SamServer.paginate(:page => params[:page],
         :select => "sam_server.*",
         :conditions => ["sam_customer_id = ?", params[:id]], :order => server_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
  render(:partial => "server_info", 
         :locals => {:server_collection => @servers,
                     :status_indicator => params[:status_indicator],
                     :update_element => params[:update_element]})
end

def update_server_subcommunity_table
  @server_subcommunity_infos = SamServerSubcommunityInfo.paginate(:page => params[:page],
          :select => "sam_server_subcommunity_info.*, (sam_server_subcommunity_info.licensed_seats - sam_server_subcommunity_info.used_seats) as difference",
          :joins => "inner join sam_server_community_info on sam_server_community_info.id = sam_server_subcommunity_info.sam_server_community_info_id \
                     inner join sam_server on sam_server.id = sam_server_community_info.sam_server_id \
                     inner join subcommunity on subcommunity.id = sam_server_subcommunity_info.subcommunity_id",
          :conditions => ["sam_customer_id = ?", params[:id]], :order => server_subcommunity_info_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
  render(:partial => "server_subcommunity_info", 
         :locals => {:server_subcommunity_info_collection => @server_subcommunity_infos,
                     :status_indicator => params[:status_indicator],
                     :update_element => params[:update_element]})
end



private

def form_subcommunity_scales(sc)
  licensing_activation_enabled = true
  available_subcommunities = sc.available_subcommunities
  subcom_scale = []
  # if the sam customer is not activated for sc-licensing, then we have a lot less work to do
  if (sc.sc_licensing_activated.nil?)
    available_subcommunities.each do |as|
      ss = SubcommunityScale.new(sc, as)
      ss.total_seat_pool_count = SeatPool.sum(:seat_count, :conditions => ["sam_customer_id = ? and subcommunity_id = ?", sc.id, as.id])
      ss.total_seat_pool_count = 0 if (ss.total_seat_pool_count.nil?)
      ss.total_sssi_count = sc.total_sssi_licenses(as)
      licensing_activation_enabled = false if (ss.total_seat_pool_count.to_i != ss.total_sssi_count.to_i)
      # we know that no allocations are pending, because the licensing tab is not enabled yet.
      ss.seat_pool_pending_reallocations = nil
      # since no allocations can be done, then no servers are waiting to check in with updated counts
      subcom_scale << ss
    end
  # else, sc-licensing is activated for the sam customer
  # we have to check the seat_activity and conversation_instance tables for status and pending activity
  else
    available_subcommunities.each do |as|
      ss = SubcommunityScale.new(sc, as)
      ss.total_seat_pool_count = SeatPool.sum(:seat_count, :conditions => ["sam_customer_id = ? and subcommunity_id = ?", sc.id, as.id])
      ss.total_seat_pool_count = 0 if (ss.total_seat_pool_count.nil?)
      ss.total_sssi_count = sc.total_sssi_licenses(as)
      if (ss.total_seat_pool_count.to_i != ss.total_sssi_count.to_i)
        # check for any outstanding seat_activity
        ss.seat_pool_pending_reallocations = SeatPool.find(:first, :select => "seat_pool.*", :joins => "inner join seat_activity on seat_activity.seat_pool_id = seat_pool.id", 
                                       :conditions => ["seat_pool.sam_customer_id = ? and seat_pool.subcommunity_id = ? and seat_activity.done = false", sc.id, as.id])
        # only disable license activation / sync servers if there are pending reallocations OR the seat pool count is less than the server-reported count
        # a seat pool count larger than the server-reported count post license activation should not stop a user from syncing the seat counts
        licensing_activation_enabled = false if (ss.total_seat_pool_count.to_i < ss.total_sssi_count.to_i) || (!ss.seat_pool_pending_reallocations.nil?)
      end
      subcom_scale << ss
    end    
  end
  return subcom_scale, licensing_activation_enabled  
end

def form_subcommunity_scale(sc, subcom)
  if (sc.sc_licensing_activated.nil?)
    ss = SubcommunityScale.new(sc, subcom)
    ss.total_seat_pool_count = SeatPool.sum(:seat_count, :conditions => ["sam_customer_id = ? and subcommunity_id = ?", sc.id, subcom.id])
    ss.total_sssi_count = sc.total_sssi_licenses(subcom)
    # we know that no allocations are pending, because the licensing tab is not enabled yet.
    ss.seat_pool_pending_reallocations = nil
  else
    ss = SubcommunityScale.new(sc, subcom)
    ss.total_seat_pool_count = SeatPool.sum(:seat_count, :conditions => ["sam_customer_id = ? and subcommunity_id = ?", sc.id, subcom.id])
    ss.total_sssi_count = sc.total_sssi_licenses(subcom)
    if (ss.total_seat_pool_count.to_i != ss.total_sssi_count.to_i)
      ss.seat_pool_pending_reallocations = SeatPool.find(:first, :select => "seat_pool.*", :joins => "inner join seat_activity on seat_activity.seat_pool_id = seat_pool.id", 
                                     :conditions => ["seat_pool.sam_customer_id = ? and seat_pool.subcommunity_id = ? and seat_activity.done = false", sc.id, subcom.id])
    end
  end
  return ss
end

def entitlement_sort_by_param(sort_by_arg)
  case sort_by_arg
     when "order_date" then "entitlement.ordered"
     when "tms_entitlement_id" then "entitlement.tms_entitlementid"
     when "product_description" then "product.description"
     when "num_licenses" then "entitlement.license_count"
     when "order_number" then "entitlement.order_num"
     when "invoice_number" then "entitlement.invoice_num"
     when "entitlement_type" then "sc_entitlement_type.description"
     when "created_at" then "entitlement.created_at"
     
     when "order_date_reverse" then "entitlement.ordered desc"
     when "tms_entitlement_id_reverse" then "entitlement.tms_entitlementid desc"
     when "product_description_reverse" then "product.description desc"
     when "num_licenses_reverse" then "entitlement.license_count desc"
     when "order_number_reverse" then "entitlement.order_num desc"
     when "invoice_number_reverse" then "entitlement.invoice_num desc"
     when "entitlement_type_reverse" then "sc_entitlement_type.description desc"
     when "created_at_reverse" then "entitlement.created_at desc"
     else "entitlement.created_at desc"
     end
end

def server_sort_by_param(sort_by_arg)
  case sort_by_arg
     when "name" then "sam_server.name"
     when "dateregistered" then "sam_server.created_at"
     
     when "name_reverse" then "sam_server.name desc"
     when "dateregistered_reverse" then "sam_server.created_at desc"
     
     else "sam_server.name"
  end
end

def server_subcommunity_info_sort_by_param(sort_by_arg)
  case sort_by_arg
    when "product_description" then "subcommunity.name"
    when "server_name" then "sam_server.name"
    when "allocated_seats" then "sam_server_subcommunity_info.licensed_seats"
    when "enrolled_seats" then "sam_server_subcommunity_info.used_seats"
    when "unused_seats" then "difference"
    
    when "product_description_reverse" then "subcommunity.name desc"
    when "server_name_reverse" then "sam_server.name desc"
    when "allocated_seats_reverse" then "sam_server_subcommunity_info.licensed_seats desc"
    when "enrolled_seats_reverse" then "sam_server_subcommunity_info.used_seats desc"
    when "unused_seats_reverse" then "difference desc"
    
    else "subcommunity.name, sam_server.name"
    end
end

class SubcommunityScale

  attr_accessor :sam_customer, :subcommunity, :total_seat_pool_count, :total_sssi_count, :seat_pool_pending_reallocations
  
  def initialize(sc, subcom)
    @sam_customer = sc
    @subcommunity = subcom
    @total_seat_pool_count = 0
    @total_sssi_count = 0
    @seat_pool_pending_reallocations = nil
  end
  
  def balanceable?
    licensing_status = self.sam_customer.licensing_status
    total_sp_count = self.total_seat_pool_count.to_i
    total_sssi_count = self.total_sssi_count.to_i
    if (!(self.seat_pool_pending_reallocations.nil?) || licensing_status == 'p')
     return false
    else
      if (licensing_status == 'n' && total_sp_count != total_sssi_count) || (total_sp_count < total_sssi_count)
        return true
      else
        return false
      end
    end
  end
  
  def install_licenses?
    ((self.sam_customer.licensing_status == 'n') && (self.total_seat_pool_count.to_i > self.total_sssi_count.to_i))
  end
  
  def count_discrepancy?
    (self.total_seat_pool_count.to_i < self.total_sssi_count.to_i)
  end
  
end

end
