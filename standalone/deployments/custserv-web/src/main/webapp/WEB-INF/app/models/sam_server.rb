require "date"
class SamServer < ActiveRecord::Base
  set_table_name "sam_server"
  belongs_to :sam_customer, :class_name => "SamCustomer", :foreign_key => "sam_customer_id"
  belongs_to :registration_entitlement, :class_name => "Entitlement", :foreign_key => "registration_entitlement_id"
  belongs_to :clone_parent, :class_name => "SamServer", :foreign_key => "clone_parent_id"
  has_one  :agent
  has_many :seats
  has_one  :sam_server_address
  has_many :sam_server_community_infos
  has_many :sam_server_school_infos
  has_many :seat_pools
  has_many :sam_server_users
  
  include SaplingsHelper
  
  STATUS_ACTIVE = 'a'
  STATUS_TRANSITIONING = 't'
  STATUS_INACTIVE = 'i'
  
  @@STATUS_ACTIVE = 'a'
  @@STATUS_TRANSITIONING = 't'
  @@STATUS_INACTIVE = 'i'
  
  TYPE_LOCAL = 0
	TYPE_HOSTED = 1
	TYPE_UNREGISTERED_GENERIC = 2
  
  @@TYPE_UNREGISTERED_GENERIC = 2
  @@TYPE_HOSTED = 1
  @@TYPE_LOCAL = 0

  def self.STATUS_ACTIVE
    return @@STATUS_ACTIVE
  end

  def SamServer.TYPE_LOCAL
    return @@TYPE_LOCAL
  end

  def SamServer.TYPE_HOSTED
    return @@TYPE_HOSTED
  end

  def SamServer.TYPE_UNREGISTERED_GENERIC
    return @@TYPE_UNREGISTERED_GENERIC
  end
  
  def self.active_server_count(samCustomer)
    cnt = SamServer.count(
      :joins => "as ss inner join agent as a on ss.id = a.sam_server_id",
      :conditions => ["ss.sam_customer_id = ? and ss.status = 'a'", samCustomer.id])
    cnt.nil? ? 0 : cnt
  end
  
  def is_Duke_or_later?
    slms_community = Community.find_by_code("SLMS")
    community_info = SamServerCommunityInfo.find_by_sam_server_id_and_community_id(self.id, slms_community.id)
    if (community_info.nil? || community_info.version.nil? || (SaplingsHelper.compare_release_versions(community_info.version, SaplingsHelper.get_duke_version) < 0) ) 
      return false
    else 
      return true
    end
  end
  
  def is_hosted_server?
    return self.server_type == 1 ? true : false
  end
  
  def is_local_server?
	self.server_type == 0
  end
  
  def active_non_transitioning?
    self.status == @@STATUS_ACTIVE
  end
  
  def transitioning?
    self.status == @@STATUS_TRANSITIONING
  end
  
  def is_cloned_server?
    !self.clone_parent.nil?    
  end
  
  # Get the number of pending requests
  def findNumPendingRequests
  	ServerReportRequest.count( :conditions => ["sam_server_id = ? and status = 'p'", self.id])
  end

  # Get the number of scheduled update requests
  def findNumScheduledUpdates
    ServerScheduledUpdateRequest.count( :conditions => ["sam_server_id = ? and status = 'p'", self.id])
  end
  
  # Get the number of pending transaction requests
  def findNumPendingTransactions
    SeatActivity.count( :select => "sa.*",
                        :joins => "sa inner join seat_pool sp on sp.id = sa.seat_pool_id",
                        :conditions => ["sp.sam_server_id = ? and sa.status = ?", self.id, SeatActivity::STATUS_UNFINISHED])
  end
  
  def self.search(params, limit=-1, sortby="ss.id")
    select_clause = "distinct ss.id, ss.name, ss.created_at, ss.status, ss.sam_customer_id, ss.guid, a.id as agent_id, a.updated_at, sc.name as sam_customer_name, c.ucn, ssai.value, sp.code, u.email, sstr.comment"
    joins_clause = "ss left join agent a on ss.id = a.sam_server_id inner join sam_customer sc on ss.sam_customer_id = sc.id inner join org on sc.root_org_id = org.id inner join customer c on org.customer_id = c.id left join sam_server_audit_info ssai on (ss.id = ssai.sam_server_id and ssai.name = 'server_audit_siteid') left join sam_server_address ssa on ss.id = ssa.sam_server_id left join state_province sp on ssa.state_province_id = sp.id "
    joins_clause += "left join sam_server_transition_request sstr on (ss.id=sstr.sam_server_id and sstr.status='p') left join users u on sstr.user_id=u.id "
    community_1_included = false
    community_2_included = false
    conditions_clause = "ss.server_type != #{SamServer.TYPE_UNREGISTERED_GENERIC} "
    conditions_clause_fillins = []
    if (params[:sam_server_id] && !params[:sam_server_id].empty?)
      conditions_clause += "and ss.id = ? "
      conditions_clause_fillins << params[:sam_server_id]
  	end
  	if (params[:active] == "1")
      conditions_clause += "and ss.status = 'a' "
    elsif (params[:active] == "2")
      conditions_clause += "and ss.status in ('t','i') "
    end
    if (params[:aggregation] == "1")
      conditions_clause += "and ss.agg_server = 1 "
    elsif (params[:aggregation] == "2")
      conditions_clause += "and ss.agg_server != 1 "
    end
    if (params[:hosted] == "1")
      conditions_clause += "and ss.server_type = 1 "
    elsif (params[:hosted] == "2")
      conditions_clause += "and ss.server_type = 0 "
    end
    if (params[:unregistered] == "1")
      conditions_clause += "and ss.server_type = 2 "
    elsif (params[:unregistered] == "2")
      conditions_clause += "and ss.server_type != 2 "
    end
    if (params[:guid] && !params[:guid].strip.empty?)
      conditions_clause += "and ss.guid like ? "
      conditions_clause_fillins << ("%" + params[:guid] + "%")
    end
    if (params[:state_id] && !params[:state_id].strip.empty?)
      conditions_clause += "and ssa.state_province_id = ? "
      conditions_clause_fillins << params[:state_id]
    end
    if (params[:installation_code] && !params[:installation_code].strip.empty?)
      conditions_clause += "and ss.installation_code like ? "
      conditions_clause_fillins << ("%" + params[:installation_code] + "%")
    end
    if (params[:sam_customer_id] && !params[:sam_customer_id].empty?)
      conditions_clause += "and sc.id = ? "
      conditions_clause_fillins << params[:sam_customer_id]
    end
    if (params[:agent_id] && !params[:agent_id].empty?)
      conditions_clause += "and a.id = ? "
      conditions_clause_fillins << params[:agent_id]
    end
    if ((params[:agent_created_at_start_date] && !params[:agent_created_at_start_date].strip.empty?) || 
  	      (params[:agent_created_at_end_date] && !params[:agent_created_at_end_date].strip.empty?))
      if ((params[:agent_created_at_start_date] && !params[:agent_created_at_start_date].strip.empty?) && 
        	    (params[:agent_created_at_end_date] && !params[:agent_created_at_end_date].strip.empty?))
            conditions_clause += "and a.created_at between '#{params[:agent_created_at_start_date]} #{params[:agent_created_at_start_time]}' and 
                          '#{params[:agent_created_at_end_date]} #{params[:agent_created_at_end_time]}'"
      elsif (params[:agent_created_at_start_date] && !params[:agent_created_at_start_date].strip.empty?)
          conditions_clause += "and a.created_at >= '#{params[:agent_created_at_start_date]} #{params[:agent_created_at_start_time]}'"
      else
          conditions_clause += "and a.created_at <= '#{params[:agent_created_at_end_date]} #{params[:agent_created_at_end_time]}'"
      end
    end
    if (params[:os_family] && !params[:os_family].nil? && !params[:os_family].empty?)
  		conditions_clause += "and a.os_family = ? "
  		conditions_clause_fillins << params[:os_family]
    end
    if (params[:cpu_bits] && !params[:cpu_bits].nil? && !params[:cpu_bits].empty?)
      conditions_clause += "and a.cpu_bits = ? "
      conditions_clause_fillins << params[:cpu_bits]
    end
    if (params[:os_series] && !params[:os_series].nil? && !params[:os_series].empty?)
      conditions_clause += "and a.os_series = ? "
      conditions_clause_fillins << params[:os_series]
    end
    if (params[:ip_address] && !params[:ip_address].strip.empty?)
      conditions_clause += "and a.last_ip like ? "
      conditions_clause_fillins << (params[:ip_address] + "%")
    end
    if (params[:poll_override_active] == "1")
      conditions_clause += "and a.poll_override is not null "
    elsif (params[:poll_override_active] == "2")
      conditions_clause += "and a.poll_override is null "
    end
    if ((params[:poll_override_exp_start_date] && !params[:poll_override_exp_start_date].strip.empty?) || 
  	      (params[:poll_override_exp_end_date] && !params[:poll_override_exp_end_date].strip.empty?))
      if ((params[:poll_override_exp_start_date] && !params[:poll_override_exp_start_date].strip.empty?) && 
        	    (params[:poll_override_exp_end_date] && !params[:poll_override_exp_end_date].strip.empty?))
        conditions_clause += "and a.poll_override_expires_at between '#{params[:poll_override_exp_start_date]} #{params[:poll_override_exp_start_time]}' and 
                          '#{params[:poll_override_exp_end_date]} #{params[:poll_override_exp_end_time]}'"
      elsif (params[:poll_override_exp_start_date] && !params[:poll_override_exp_start_date].strip.empty?)
          conditions_clause += "and a.poll_override_expires_at >= '#{params[:poll_override_exp_start_date]} #{params[:poll_override_exp_start_time]}'"
      else
          conditions_clause += "and a.poll_override_expires_at <= '#{params[:poll_override_exp_end_date]} #{params[:poll_override_exp_end_time]}'"
      end
    end
    if (params[:ignore_agent] == "1")
      conditions_clause += "and a.ignore_agent = 1 "
    elsif (params[:ignore_agent] == "2")
      conditions_clause += "and a.ignore_agent != 1 "
    end
  	if ((params[:registered_at_start_date] && !params[:registered_at_start_date].strip.empty?) || 
  	      (params[:registered_at_end_date] && !params[:registered_at_end_date].strip.empty?))
      if ((params[:registered_at_start_date] && !params[:registered_at_start_date].strip.empty?) && 
        	    (params[:registered_at_end_date] && !params[:registered_at_end_date].strip.empty?))
            conditions_clause += "and ss.created_at between '#{params[:registered_at_start_date]} #{params[:registered_at_start_time]}' and 
                          '#{params[:registered_at_end_date]} #{params[:registered_at_end_time]}'"
      elsif (params[:registered_at_start_date] && !params[:registered_at_start_date].strip.empty?)
          conditions_clause += "and ss.created_at >= '#{params[:registered_at_start_date]} #{params[:registered_at_start_time]}'"
      else
          conditions_clause += "and ss.created_at <= '#{params[:registered_at_end_date]} #{params[:registered_at_end_time]}'"
      end
      #conditions_clause_fillins << params[:registered_at_start_date] << params[:registered_at_start_time] 
    end
    if ((params[:updated_at_start_date] && !params[:updated_at_start_date].strip.empty?) || 
  	      (params[:updated_at_end_date] && !params[:updated_at_end_date].strip.empty?))
      if ((params[:updated_at_start_date] && !params[:updated_at_start_date].strip.empty?) && 
        	    (params[:updated_at_end_date] && !params[:updated_at_end_date].strip.empty?))
            conditions_clause += "and ss.updated_at between '#{params[:updated_at_start_date]} #{params[:updated_at_start_time]}' and 
                          '#{params[:updated_at_end_date]} #{params[:updated_at_end_time]}'"
      elsif (params[:updated_at_start_date] && !params[:updated_at_start_date].strip.empty?)
          conditions_clause += "and ss.updated_at >= '#{params[:updated_at_start_date]} #{params[:updated_at_start_time]}'"
      else
          conditions_clause += "and ss.updated_at <= '#{params[:updated_at_end_date]} #{params[:updated_at_end_time]}'"
      end 
    end
    if (params[:community_name1] && !params[:community_name1].empty?)
      community_1_included = true
      joins_clause += "inner join sam_server_community_info ssci1 on ssci1.sam_server_id = ss.id "
      conditions_clause += "and ssci1.community_id = ? "
      conditions_clause_fillins << params[:community_name1]
    end
    if (community_1_included && params[:community_min_version1] && !params[:community_min_version1].empty?)
      conditions_clause += "and ssci1.version >= ? "
      conditions_clause_fillins << params[:community_min_version1]
    end
    if (community_1_included && params[:community_max_version1] && !params[:community_max_version1].empty?)
      conditions_clause += "and ssci1.version <= ? "
      conditions_clause_fillins << params[:community_max_version1]
    end
    if (params[:community_name2] && !params[:community_name2].empty?)
      community_2_included = true
      joins_clause += "inner join sam_server_community_info ssci2 on ssci2.sam_server_id = ss.id "
      conditions_clause += "and ssci2.community_id = ? "
      conditions_clause_fillins << params[:community_name2]
    end
    if (community_2_included && params[:community_min_version2] && !params[:community_min_version2].empty?)
      conditions_clause += "and ssci2.version >= ? "
      conditions_clause_fillins << params[:community_min_version2]
    end
    if (community_2_included && params[:community_max_version2] && !params[:community_max_version2].empty?)
      conditions_clause += "and ssci2.version <= ? "
      conditions_clause_fillins << params[:community_max_version2]
    end
    if (params[:enforce_school_max_enroll_cap] == "1")
      conditions_clause += "and ss.enforce_school_max_enroll_cap = true "
    elsif (params[:enforce_school_max_enroll_cap] == "2")
      conditions_clause += "and ss.enforce_school_max_enroll_cap = false "
    end
    if (params[:name] && !params[:name].strip.empty?)
      conditions_clause += "and ss.name like ? "
  		conditions_clause_fillins << ("%" + params[:name] + "%")
    end
    if (params[:registration_entitlement_tms_id] && !params[:registration_entitlement_tms_id].empty?)
      joins_clause += "inner join entitlement e on ss.registration_entitlement_id = e.id "
      conditions_clause += "and e.tms_entitlementid = ? " #note that this is a varchar in the DB, not a real integer ID. Requiring exact string match here
      conditions_clause_fillins << (params[:registration_entitlement_tms_id])
    end
    if (params[:last_checkin_date] && !params[:last_checkin_date].empty?)
      if (params[:checked_in_since].to_i > 0)
        conditions_clause += "and a.updated_at >= ? "
      else
        conditions_clause += "and a.updated_at <= ? "
      end
      conditions_clause_fillins << (params[:last_checkin_date])
    end
    if (params[:registration_siteid] && !params[:registration_siteid].empty?)
      conditions_clause += "and ssai.value = ? "
      conditions_clause_fillins << (params[:registration_siteid])
    end
    if (params[:agent_plugin] && !params[:agent_plugin].empty?)
      agent_plugin_included = true
      joins_clause += "inner join agent_plugin ap on ap.agent_id = a.id "
      conditions_clause += "and ap.name = ? "
      conditions_clause_fillins << params[:agent_plugin]
    end
    if (agent_plugin_included && params[:agent_plugin_min_version] && !params[:agent_plugin_min_version].empty?)
      if (agent_plugin_included && params[:agent_plugin_max_version] && !params[:agent_plugin_max_version].empty?)  
        conditions_clause += "and ap.value >= #{params[:agent_plugin_min_version]} and ap.value <= #{params[:agent_plugin_max_version]} "
      else
        conditions_clause += "and ap.value >= #{params[:agent_plugin_min_version]} "
      end
    else
      if (agent_plugin_included && params[:agent_plugin_max_version] && !params[:agent_plugin_max_version].empty?)  
        conditions_clause += "and ap.value <= #{params[:agent_plugin_max_version]} "
      end
    end
    if (params[:flagged_for_deactivation] == "1")
      conditions_clause += "and sstr.status = ? "
      conditions_clause_fillins << SamServerTransitionRequest.STATUS_PENDING
    end
        
    if(limit > 0)
      find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => sortby, :limit => limit)
    else #negative value of limit indicates no limit
      find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => sortby)
    end
  end
  
  def self.get_recently_installed
    start_date = Date.today - 7
    find_by_sql("select sc.id as sam_customer_id, sc.name as sam_customer_name, sp.code as state_code, ss.created_at as server_registration_date, ss.server_type,
                  ss.id as sam_server_id, ss.name as sam_server_name, sc.registration_date, if(sc.registration_date >= (curdate() - 7),1,null) as new_customer
                  from sam_customer sc
                  inner join sam_server ss on ss.sam_customer_id = sc.id
                  inner join org o on sc.root_org_id = o.id
                  inner join customer c on o.customer_id = c.id
                  inner join customer_address ca on ca.customer_id = c.id
                  inner join state_province sp on ca.state_province_id = sp.id
                  inner join address_type adt on ca.address_type_id = adt.id
                  where adt.code = '#{AddressType.MAILING_CODE}' and ss.created_at >= '#{start_date} 00:00:00' order by ss.created_at desc")
  end
  
  def self.find_products_installed_on_server (server)
    sql = <<EOS
       select p.* from product p
         inner join subcommunity scom on p.id = scom.product_id
         inner join sam_server_subcommunity_info ss_sci on ss_sci.subcommunity_id = scom.id
         inner join sam_server_community_info ss_ci on ss_sci.sam_server_community_info_id = ss_ci.id
       where 
         ss_ci.sam_server_id = #{server.id} and 
         ss_ci.enabled = 1    
EOS
    Product.find_by_sql(sql)
  end
 
  def self.get_all_license_counts(server_id)
    SamServerSubcommunityInfo.find_by_sql(["select distinct s.name, s.id as subcommunity_id, sp.id as seat_pool_id, sp.seat_count as sc_allocated_count, sssi.licensed_seats as ss_allocated_count, 
                                            sssi.used_seats as ss_enrolled_count, sslc.licensed_seats as initial_ss_allocated_count,
                                            sslc.used_seats as initial_ss_enrolled_count from sam_server_subcommunity_info sssi
                                            inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id 
                                            inner join sam_server ss on ssci.sam_server_id = ss.id inner join subcommunity s on sssi.subcommunity_id = s.id 
                                            left join snapshot_server_license_counts sslc on (sslc.sam_server_id = ss.id and sslc.event_type in (?,?) and sslc.subcommunity_id = s.id) 
                                            left join seat_pool sp on (sp.subcommunity_id = s.id and sp.sam_server_id = ss.id) where ss.id = ? order by s.name", 
                                            SnapshotServerLicenseCount.INITIAL_REGISTRATION_CODE, SnapshotServerLicenseCount.INITIAL_LICENSING_ACTIVATION_CODE, server_id])
  end
  
  def is_unregistered_generic?
	  self.server_type == SamServer::TYPE_UNREGISTERED_GENERIC
  end

  def is_dashboard_export_blacklisted
      blacklist_count = ConvExportBlacklistByServer.find_by_sql(["SELECT count(1) as the_count FROM scholastic.conv_export_blacklist_by_server c where c.sam_server_id = ?", self.id])[0].the_count
      return blacklist_count == "0" ? false : true;
  end
  
  def unignore_guid_date_part
    return (self.unignore_guid_date.nil?) ? "" : self.unignore_guid_date.strftime("%Y-%m-%d")
  end
  
  def unignore_guid_time_part
    return (self.unignore_guid_date.nil?) ? "" : self.unignore_guid_date.strftime("%H:%M:%S")
  end
  
  
  def flag_for_deactivation(user, comment=nil)
    # caller should be checking flagged_for_deactivation? first
    transition_request = SamServerTransitionRequest.new(:sam_server => self,
                                                        :user => user,
                                                        :process_type_code => SamServerTransitionRequest.DEACTIVATION_CODE,
                                                        :comment => comment)
    transition_request.save!
  end
  
  def flagged_for_deactivation?
    (SamServerTransitionRequest.find(:first, :conditions => { :sam_server_id => self.id, :status => SamServerTransitionRequest.STATUS_PENDING, :process_type_code => SamServerTransitionRequest.DEACTIVATION_CODE }) ? true : false)
  end
  
  def flagged_for_deactivation_by_user?(user)
    (SamServerTransitionRequest.find(:first, :conditions => { :sam_server_id => self.id, :status => SamServerTransitionRequest.STATUS_PENDING, :process_type_code => SamServerTransitionRequest.DEACTIVATION_CODE, :user_id => user.id }) ? true : false)
  end
  
  # for callers who need info within the SamServerTransitionRequest object, not just a boolean
  def get_pending_deactivation_request
    SamServerTransitionRequest.find(:first, :conditions => { :sam_server_id => self.id, :status => SamServerTransitionRequest.STATUS_PENDING, :process_type_code => SamServerTransitionRequest.DEACTIVATION_CODE })
  end
  
  
  def reset_request_pending?(sam_server_reset_request_type_code)
    (SamServerResetRequest.find(:first, :conditions => { :sam_server_id => self.id, :status => SamServerResetRequest.STATUS_PENDING, :code => sam_server_reset_request_type_code }) ? true : false)
  end
  
  def request_reset(user, sam_server_reset_request_type_code)
    # caller should be checking reset_request_pending? first
    reset_request = SamServerResetRequest.new(:sam_server => self,
                                              :user => user,
                                              :code => sam_server_reset_request_type_code)
    reset_request.save!
  end
  
  
  # cancel any pending server deactivation request for this server (schema only allows 1).
  def cancel_deactivation_request
    request_to_cancel = SamServerTransitionRequest.find(:first, :conditions => { :sam_server_id => self.id, :status => SamServerTransitionRequest.STATUS_PENDING, :process_type_code => SamServerTransitionRequest.DEACTIVATION_CODE })
    if request_to_cancel
      request_to_cancel.cancel
      request_to_cancel.save!
    end
  end
  
  # revoke any pending server deactivation request for this server (schema only allows 1). same as cancel but different status for audit
  def revoke_deactivation_request
    request_to_revoke = SamServerTransitionRequest.find(:first, :conditions => { :sam_server_id => self.id, :status => SamServerTransitionRequest.STATUS_PENDING })
    if request_to_revoke
      request_to_revoke.revoke
      request_to_revoke.save!
    end
  end
  
  def get_display_status
    return 'Active' if self.active_non_transitioning?
    return 'Transitioning' if self.transitioning?
    'Inactive'
  end
  
  # determine if this SamServer has licenses as tracked by SAMC (at least one nonzero SeatPool)
  def has_seats_allocated?
    SeatPool.find(:first, :conditions => ["sam_server_id = ? AND seat_count > 0", self.id]) ? true : false
  end
  
  # determine if this SamServer has licenses as reported by SAM (at least one nonzero SamServerSubcommunityInfo)
  def has_licenses_reported?
    SamServerSubcommunityInfo.find(:first, 
                                   :joins => "INNER JOIN sam_server_community_info ssci ON sam_server_subcommunity_info.sam_server_community_info_id = ssci.id",
                                   :conditions => ["ssci.sam_server_id = ? AND sam_server_subcommunity_info.licensed_seats > 0", self.id]) ? true : false
  end
  
  def has_licenses?
    ( has_seats_allocated? or has_licenses_reported? )
  end
  
  # static wrapper around has_licenses? method for callers that have an Array of SamServers and want to know if any have licenses.
  def self.servers_have_licenses?(sam_servers)
    sam_servers.each do |sam_server| 
      return true if sam_server.has_licenses?
    end
    
    false
  end
  
  # static wrapper around findNumScheduledUpdates for callers that just want to know if any SamServers in the given Array have pending server_scheduled_update_requests.
  def self.servers_have_pending_scheduled_updates?(sam_servers)
    
    sam_servers.each do |sam_server| 
      return true if (sam_server.findNumScheduledUpdates > 0)
    end
    
    false
  end
  
  # static wrapper around findNumScheduledUpdates for callers that just want to know if any SamServers in the given Array have pending server_report_requests.
  def self.servers_have_pending_reports?(sam_servers)
    
    sam_servers.each do |sam_server| 
      return true if (sam_server.findNumPendingRequests > 0)
    end
    
    false
  end
  
  
  # get the Array of deactivation data points that are needed for deactivating this sam_server, particularly the view where user choose license handling options.
  # the returned Array has Hash elements that represent one subcommunity. example for server with two licensed subcommunities:
  #    [ {id: 1, subcommunity_name: iRead, licenses_to_keep: 5}, {id: 2, subcommunity_name: System 44, licenses_to_keep: 0} ]
  def get_deactivation_info
    sam_server_deactivation_info = []
    
    self.seat_pools.each do |seat_pool|
      sam_server_deactivation_info_seat_pool = Hash.new
      subcommunity_name = seat_pool.subcommunity.name || " "
      sam_server_deactivation_info_seat_pool["id"] = seat_pool.id
      sam_server_deactivation_info_seat_pool["subcommunity_name"] = subcommunity_name
      sam_server_deactivation_info_seat_pool["seat_count"] = seat_pool.seat_count
      
      #do math here to offer the option of keeping only the number of licenses that are backed by non-virtual entitlement seat counts
      total_virtual_license_count = Entitlement.total_virtual_license_count(self.sam_customer, seat_pool.subcommunity)
      logger.debug "Total virtual licenses of " + subcommunity_name + " for SAM Customer " + self.sam_customer.id.to_s + ": " + total_virtual_license_count.to_s
      
      net_sum_plcc = Task.net_sum_of_plcc_tasks(self.sam_customer, seat_pool.subcommunity)
      overall_sum = net_sum_plcc + seat_pool.seat_count
      
      if(total_virtual_license_count.nil? || total_virtual_license_count < 1)
        #if virtual count is 0, keep all licenses
        sam_server_deactivation_info_seat_pool["licenses_to_keep"] = [ [ overall_sum, 0].max, seat_pool.seat_count ].min
      elsif(total_virtual_license_count <= overall_sum)
        #some are virtuals, keep the non-virtuals, we'll discard the rest
        sam_server_deactivation_info_seat_pool["licenses_to_keep"] = [ [ overall_sum - total_virtual_license_count, 0].max, seat_pool.seat_count ].min
      else
        #more virtuals than the total (seat_pool.seat_count + net_sum_plcc). so the only thing limiting how many we can discard is the PLCC count
        sam_server_deactivation_info_seat_pool["licenses_to_keep"] = [ [  -1 * net_sum_plcc, 0].max, seat_pool.seat_count ].min # *keep* the PLCC amount 
      end
      sam_server_deactivation_info_seat_pool["licenses_to_discard"] = seat_pool.seat_count - sam_server_deactivation_info_seat_pool["licenses_to_keep"]
      logger.debug "Default " + subcommunity_name + " licenses to keep is " + sam_server_deactivation_info_seat_pool["licenses_to_keep"].to_s + " for SAM Customer " + self.sam_customer.id.to_s
    
      if( overall_sum < 0 )
        sam_server_deactivation_info_seat_pool["max_discardable"] = 0
      elsif( overall_sum > seat_pool.seat_count )
        sam_server_deactivation_info_seat_pool["max_discardable"] = seat_pool.seat_count
      else
        sam_server_deactivation_info_seat_pool["max_discardable"] = overall_sum
      end
      
      sam_server_deactivation_info << sam_server_deactivation_info_seat_pool
    end
    
    return sam_server_deactivation_info
  end
  
end

# == Schema Information
#
# Table name: sam_server
#
#  id                              :integer(10)     not null, primary key
#  license_management_level        :string(255)
#  name                            :string(255)
#  created_at                      :datetime
#  updated_at                      :datetime
#  guid                            :string(36)      not null
#  installation_code               :string(255)
#  registration_entitlement_id     :integer(10)
#  sam_customer_id                 :integer(10)     not null
#  agg_server                      :boolean
#  enforce_school_max_enroll_cap   :boolean         default(FALSE)
#  active                          :boolean         default(TRUE), not null
#  school_info_digest              :string(255)
#  teacher_digest                  :string(255)
#  reg_token                       :string(36)
#  reg_token_used_at               :datetime
#  registration_mode               :integer(10)     default(0), not null
#  server_type                     :integer(10)     default(0), not null
#  school_teacher_digest           :string(255)
#  auth_vetted                     :boolean         default(FALSE), not null
#  e21_student_digest              :string(255)
#  school_e21_student_digest       :string(255)
#  admin_digest                    :string(255)
#  status                          :string(1)       default("a"), not null
#  clone_parent_id                 :integer(10)
#  ldap_server                     :boolean
#  school_admin_digest             :string(255)
#  published                       :boolean         default(FALSE), not null
#  uri_scheme                      :string(255)
#  uri_host                        :string(255)
#  uri_port                        :integer(10)
#  uri_path_prefix                 :string(255)
#  ng_student_digest               :string(255)
#  ng_class_student_digest         :string(255)
#  student_digest                  :string(255)
#  update_teacher_classmappings_at :datetime
#  auto_resolve_lcd                :boolean         default(TRUE), not null
#

