require 'java'
import 'java.util.HashMap'
import 'java.lang.Character'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
class SamCustomerSubcommunitiesController < SamCustomersController
  
  before_filter :load_subcommunity, :set_breadcrumb
  
  #layout 'new_layout_with_jeff_stuff'
  layout 'default'
  
  def index
    @license_count_comparisons, @resyncable = @sam_customer.build_seat_count_profile(nil, nil)
    
    #Get all product_IDs for products relevant to license conversions

	product_list = []
	@license_conversions_list = []
	
	product_list << Product.find_by_id_value('10021') #R180NG Conversion Stage A
	product_list << Product.find_by_id_value('10022') #R180NG Conversion Stage B
	product_list << Product.find_by_id_value('10023') #R180NG Conversion Stage C
	product_list << Product.find_by_id_value('10030') #Fastt Math NG Conversion
	product_list << Product.find_by_id_value('10034') #S44 NG Conversion
	
	product_list.each do |product_obj|
		conver_lic_list_by_product = []
		conver_lic_list_by_product << product_obj.description #cllbp[0] = product name
		
		conversions_avail = ConversionLicense.find_by_sam_customer_and_product(@sam_customer, product_obj)
		if(!conversions_avail.nil?)
			conver_lic_list_by_product << conversions_avail.unconverted_count #cllbp[1] = unconverted count
						
			pre_product_obj = Product.find_by_id(product_obj.conversion_product_map.pre_converted_product_id)
			
			#cllbp[2] = ee license count
			conver_lic_list_by_product << SeatPool.seat_count_unassigned(@sam_customer, pre_product_obj.subcommunity)
			
			conver_lic_list_by_product << conversions_avail.converted_count #cllbp[3] = converted count
		
		else
			conver_lic_list_by_product << 0 #cllbp[1] = unconverted count
			
			pre_product_obj = Product.find_by_id(product_obj.conversion_product_map.pre_converted_product_id)
			
			#cllbp[2] = ee license count
			conver_lic_list_by_product << SeatPool.seat_count_unassigned(@sam_customer, pre_product_obj.subcommunity)
			
			conver_lic_list_by_product << 0 #cllbp[3] = converted count
		end
		@license_conversions_list << conver_lic_list_by_product
	end
	
    @widget_list << Widget.new("conversion_policy", "License Conversion Policy", nil, 500, 900)
    @widget_list << Widget.new("active_license_count_information", "Active License Count Information", nil, 600, 700) 
    #@prototype_required = true
  end
  
  def show
    @subcommunity = Subcommunity.find(params[:id])
    @unallocated_seat_pool = SeatPool.find_by_sam_customer_id_and_subcommunity_id(@sam_customer.id, @subcommunity.id, :conditions => "sam_server_id is null")
	  @unregistered_pool = @sam_customer.unregistered_pool(@subcommunity.id)
    @unallocated_count = (@unallocated_seat_pool.nil?) ? "N/A" : @unallocated_seat_pool.seat_count.to_s
    @license_count_comparisons = SamServerSubcommunityInfo.counts_compared_with_seat_pool(params[:sam_customer_id], params[:id])
    @mirror_hash = {}
    @license_count_comparisons.each do |lcc|
      if @mirror_hash[lcc.installation_code].nil?
        @mirror_hash[lcc.installation_code] = 1
      else
        @mirror_hash[lcc.installation_code] += 1
      end
    end
    
    @chart_support = true
    @widget_list << Widget.new("conversion_policy", "License Conversion Policy", nil, 500, 900)
    #@widget_list << Widget.new("entitlement_event_history", "Entitlement Event History", nil, 600, 700)
    #@widget_list << Widget.new("seat_pool_history", "Seat Pool History", nil, 600, 700)
    #@widget_list << Widget.new("server_count_history", "Server Count History", nil, 600, 700)
    @widget_list << Widget.new("global_license_allocation_policy", "Global License Allocation Policy", nil, 600, 700)
	@widget_list << Widget.new("licensing_audit_trail", "Licensing Audit Trail", nil, 600, 700)
  end
	
	
	def seat_pool_history
		subcommunity = Subcommunity.find(params[:id])
		# TODO: get the most recent audit messages for seat pool count changes
		seat_pool_msgs = AuditMessage.find_all_seat_pool_messages_for_subcommunity(@sam_customer.id, subcommunity.id)
		#@server_count_msgs = AuditMessage.find_all_server_license_count_messages_for_subcommunity(@sam_customer.id, @subcommunity.id)
		render(:partial => "seat_pool_history", :locals => {:subcommunity => subcommunity, :seat_pool_msgs => seat_pool_msgs})
	end
 
  ################# 
  # AJAX ROUTINES #
  #################
  
  
  def license_types_for
	  @product_list = Product.find(:all, :conditions => "sam_server_product = true")
	  license_types = Entitlement.index_by_license_type(@sam_customer)
	  @license_types = {}
	  license_types.each {|lt| @license_types["#{lt.product_id}_#{lt.license_type_code}"] = lt}
	  @hosted_compliance_counts = @sam_customer.hosted_compliance_counts
	  logger.info("e21 compliance counts: #{@sam_customer.e21_compliance_counts.to_yaml}")
	  @e21_compliance_counts = @sam_customer.e21_compliance_counts
	  #@compliance_counts << @sam_customer.e21_compliance_counts
	  #@hosted_compliance_counts.flatten!
	  render(:partial => "show_license_types", :locals => {:product_list => @product_list, :license_types => @license_types, 
	    :hosted_compliance_counts => @hosted_compliance_counts, :e21_compliance_counts => @e21_compliance_counts})
    logger.info "exited license_types"
  end
  
  def license_conversion_policy_for
    @conversion_license_pool = nil
    @conversion_audits = []
    net_plcc_count = @sam_customer.net_plcc_count(@subcommunity.id)
    virtual_entitlement_count = @sam_customer.virtual_entitlement_count(@subcommunity.id)
    product = @subcommunity.product
    @product_mapping = product.conversion_product_map_for_pre
    @product_mapping = product.post_entry_in_conversion_product_map if @product_mapping.nil?
    if (@product_mapping)
      conversion_product = @product_mapping.product
      @conversion_license_pool = ConversionLicense.find_by_sam_customer_and_product(@sam_customer, conversion_product)
      logger.info("conversion license pool: #{@conversion_license_pool}")
      @conversion_audits = @conversion_license_pool.conversion_audits.sort {|a,b| b.created_at <=> a.created_at} if @conversion_license_pool
    end
    render(:partial => "conversion_policy", :locals => {:conversion_license_pool => @conversion_license_pool, :conversion_audits => @conversion_audits,
              :net_plcc_count => net_plcc_count, :virtual_entitlement_count => virtual_entitlement_count, :subcommunity => @subcommunity, :conversion_product_mapping => @product_mapping})
    logger.info("exited license_conversion_policy_for")
  end
  
  def global_allocation_policy_for
    @subcommunity = Subcommunity.find(params[:subcommunity_id])
    @allocated_on_hosted_servers = @sam_customer.hosted_allocated_subscription_count(@subcommunity)
    @seat_count_profile = GlobalSeatCountProfile.new(@sam_customer, @subcommunity)
    
    render(:partial => "global_allocation_policy", :locals => {:seat_count_profile => @seat_count_profile})
  end
  
  def licensing_audit_trail_for
	@subcommunity = Subcommunity.find(params[:subcommunity_id])
	puts "Gathering all seat pool messages.."
      @history = AuditMessage.find_by_sql("select am.*, ss.id as server_id, ifnull(ss.name,'UNALLOCATED') as server_name, amp1.value, ss.status, 'SAMC' as event_type from audit_message am " +
          "inner join audit_message_prop amp3 on (amp3.audit_message_id = am.id and amp3.name = 'subcommunityId' and amp3.value = '#{@subcommunity.id}') " +
          "inner join audit_message_prop amp4 on (amp4.audit_message_id = am.id and amp4.name = 'serverId') " +
          "left join sam_server ss on ss.id = amp4.value " +
          "inner join audit_message_prop amp1 on (amp1.audit_message_id = am.id and amp1.name = 'seatCount') " +
          "where am.sam_customer_id = #{@sam_customer.id} and am.resource_id like 'P_%' " +
          "order by am.id")
      puts "Gathering all server count messages.."
      @history.concat(AuditMessage.find_by_sql("select am.*, ss.id as server_id, ss.name as server_name, amp1.value, ss.status, 'SERVER' as event_type from audit_message am
          inner join audit_message_prop amp3 on (amp3.audit_message_id = am.id and amp3.name = 'subcommunityId' and amp3.value = '#{@subcommunity.id}')
          inner join audit_message_prop amp4 on (amp4.audit_message_id = am.id and amp4.name = 'serverId')
          inner join sam_server ss on ss.id = amp4.value
          inner join audit_message_prop amp1 on (amp1.audit_message_id = am.id and amp1.name = 'seatCount')
          where am.sam_customer_id = #{@sam_customer.id} and am.resource_id like 'A_%'
          order by am.id"))
      puts "Gathering Pending License Count Changes.."
      @history.concat(AuditMessage.find_by_sql("select t.id, t.created_at as timestamp, ss.id as server_id, ifnull(ss.name,'UNALLOCATED') as server_name, 
          ss.status, tp2.value, tp4.value as reason, 'OPENPLCC' as event_type
          from tasks t inner join task_params tp1 on (tp1.task_id = t.id and tp1.name = 'seatPoolId')
          inner join seat_pool sp on tp1.value = sp.id
          inner join subcommunity s on sp.subcommunity_id = s.id
          left join sam_server ss on sp.sam_server_id = ss.id
          inner join task_params tp2 on (tp2.task_id = t.id and tp2.name = 'delta')
          inner join task_params tp3 on (tp3.task_id = t.id and tp3.name = 'subcommunityId')
          inner join task_params tp4 on (tp4.task_id = t.id and tp4.name = 'reason')
          where t.sam_customer_id = #{@sam_customer.id} and tp3.value = '#{@subcommunity.id}'
          order by t.id"))
      @history.concat(AuditMessage.find_by_sql("select t.id, te.created_at as timestamp, ss.id as server_id, ifnull(ss.name,'UNALLOCATED') as server_name, 
          ss.status, tp2.value, tp4.value as reason, 'CLOSEPLCC' as event_type
          from tasks t inner join task_params tp1 on (tp1.task_id = t.id and tp1.name = 'seatPoolId')
          inner join task_events te on (te.task_id = t.id and te.action = 'c')
          inner join seat_pool sp on tp1.value = sp.id
          inner join subcommunity s on sp.subcommunity_id = s.id
          left join sam_server ss on sp.sam_server_id = ss.id
          inner join task_params tp2 on (tp2.task_id = t.id and tp2.name = 'delta')
          inner join task_params tp3 on (tp3.task_id = t.id and tp3.name = 'subcommunityId')
          inner join task_params tp4 on (tp4.task_id = t.id and tp4.name = 'reason')
          where t.sam_customer_id = #{@sam_customer.id} and tp3.value = '#{@subcommunity.id}'
          order by t.id"))
      puts "Gathering Server Operations.."
      @history.concat(AuditMessage.find_by_sql("select p.id, if(p.process_type_code='SSD','SD','ST') as reason, 'SERVEROP' as event_type, p.started_at as timestamp,
          ss.id as server_id, ss.name as server_name, ss.status, pc2.value as value, pc3.value as active
          from processes p inner join process_contexts pc on (pc.process_id = p.id and pc.name='resource')
          inner join sam_server ss on (pc.value = ss.id)
          left join process_contexts pc2 on (pc2.process_id = p.id and pc2.name='oldSamCustomerId')
          left join process_contexts pc3 on (pc3.process_id = p.id and pc3.name='newSamCustomerId')
          where p.process_type_code in ('SSD','SSM') and (ss.sam_customer_id = #{@sam_customer.id} or pc2.value = #{@sam_customer.id} or pc3.value = #{@sam_customer.id})"))
      puts "Collating history.."
      @history.sort!{|a,b| a.timestamp <=> b.timestamp}
      render(:partial => "licensing_audit_trail", :locals => {:history => @history})
  end
  
  
  def perform_license_audit
    flash[:notice] = "Failed to complete license audit." # default to failure message, overwrite with success message upon success
    flash[:msg_type] = "error"
    
    payload = {
      :samCustomerId => params[:sam_customer_id],
      :method_name => 'audit_license_count_integrity' # this is sort of a misnomer, the handler checks for LCD, LCI, and other stuff (not just LCI).
    }
    
    logger.info "submitting request to perform license audit with payload: #{payload.to_yaml}"
    response = CustServServicesHandler.new.dynamic_new_licensing_audit( request.env['HTTP_HOST'], payload, CustServServicesHandler::ROUTES['utilities_web_services'] )
    
    logger.info "response.type = #{response.type}, code = #{response.code}"
    if response
      if response.type == 'success'
        success_message = "License audit complete. Check for newly created license tasks."
        logger.info success_message
        flash[:notice] = success_message
        flash[:msg_type] = "info"
      else
        logger.error "ERROR: non-success response for request to perform license audit: #{response.type} : #{response.body}"
      end
    else logger.error "ERROR: no response from Web API call to perform license audit"
    end
    
    redirect_to :back
  end
  
  
  protected
  
  def load_subcommunity
    @subcommunity = Subcommunity.find(params[:subcommunity_id]) if params[:subcommunity_id]
  end
  
  def set_breadcrumb
    @site_area_code = LICENSE_COUNTS_CODE
  end
  
end


class GlobalSeatCountProfile

	attr_accessor :subcommunity, :unallocated_count, :unregistered_count,
					:allocated_on_hosted_servers, :max_allowed_on_hosted_servers, :allocated_on_local_servers, :max_allowed_on_local_servers,
					:total_active_hosted_subscriptions, :product_group_allocated_on_hosted_servers
					
	def initialize(sam_customer, subcommunity)
		@allocated_on_hosted_servers = nil
		@max_allowed_on_hosted_servers = nil
		@allocated_on_local_servers = nil
		@max_allowed_on_local_servers = nil
		@subcommunity = subcommunity
		product_is_hosted = (!@subcommunity.product.hosted_product.nil?)
		@unallocated_count = SeatPool.seat_count_unassigned(sam_customer, @subcommunity).to_i
    
    unregistered_server = sam_customer.unregistered_generic_server
		@unregistered_count = unregistered_server ? SeatPool.seat_count_for_server(sam_customer.unregistered_generic_server, @subcommunity).to_i : 0
		@allocated_on_local_servers = sam_customer.local_allocated_count(@subcommunity)
		@max_allowed_on_local_servers = sam_customer.max_seats_on_local_servers(@subcommunity)
		@allocated_on_hosted_servers = sam_customer.hosted_allocated_subscription_count(@subcommunity)
		@product_group_allocated_on_hosted_servers = sam_customer.product_group_hosted_allocated_subscription_count(@subcommunity)
		@max_allowed_on_hosted_servers = sam_customer.max_seats_on_hosted_servers(@subcommunity)
		@total_active_hosted_subscriptions = sam_customer.hosted_total_active_subscription_count(@subcommunity)
	end
	
end

class Mime::Type
  delegate :split, :to => :to_s
end

class ComplianceCounts
  
  attr_accessor :product_description, :active_count, :allocated_count
  
  def initialize(product_description, active_count, allocated_count)
    @product_description = product_description
    @active_count = active_count
    @allocated_count = allocated_count
  end
  
end
