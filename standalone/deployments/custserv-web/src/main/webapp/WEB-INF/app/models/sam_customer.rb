import 'java.lang.Character'
class SamCustomer < ActiveRecord::Base
  set_table_name "sam_customer"
  belongs_to :root_org, :class_name => "Org", :foreign_key => "root_org_id"
  belongs_to :sam_time_zone
  has_one :blackout_filter
  belongs_to :scholastic_index
  has_many :entitlements
  has_many :sam_servers, :foreign_key => "sam_customer_id", :class_name => "SamServer"
  has_many :users
  has_many :seat_pools
  belongs_to :source_entitlement, :foreign_key => "source_entitlement_id", :class_name => "Entitlement"
  belongs_to :source_user, :foreign_key => "source_user_id", :class_name => "User"
  has_many :entitlement_known_destinations
  has_many :auth_users
  has_one :lm_conversion_blacklist, :foreign_key => "sam_customer_id", :class_name => "LmConversionBlacklist"
  
  @@LICENSE_MANAGER = "licensing"
  @@UPDATE_MANAGER = "server_update"
  
  @@MANAGER_NOT_ACTIVATED = 'n'
  @@MANAGER_PENDING_ACTIVATION = 'p'
  @@MANAGER_ENABLED = 'a'
  @@MANAGER_DISABLED = 'd'
  @@MANAGER_CERTIFIED = 'c'
  
  CLEVER_STATUSES = {
    "" => "N/A",
    "u" => "Unverified Clever ID.",
    "p" => "Pending User Confirmation.",
    "v" => "Verified By User.",
    "c" => "Clever ID Set.",
    "f" => "Problem verifying or saving Clever ID.",
    "t" => "Updating Clever data in SAM."
  }
  
  def self.LICENSE_MANAGER
    @@LICENSE_MANAGER
  end
  
  def self.UPDATE_MANAGER
    @@UPDATE_MANAGER
  end
  
  def self.MANAGER_NOT_ACTIVATED
    @@MANAGER_NOT_ACTIVATED
  end
  
  def self.MANAGER_PENDING_ACTIVATION
    @@MANAGER_PENDING_ACTIVATION
  end
  
  def self.MANAGER_ENABLED
    @@MANAGER_ENABLED
  end
  
  def self.MANAGER_DISABLED
    @@MANAGER_DISABLED
  end
  
  def self.MANAGER_CERTIFIED
    @@MANAGER_CERTIFIED
  end
  
  validates_presence_of :name
  
  def ucn
    if (self.root_org)
      self.root_org.customer.ucn
    else
      nil
    end
  end
  
  # return this SAM customer's License Manager version if any, else return nil.
  # License Manager status (enrolled, certified, etc) is not considered.
  # TODO: support non-integral versions
  def license_manager_version
    lm_component = SamCustomerSamcComponent.find_by_sam_customer_and_component_code(self, "LM")
    lm_component ? lm_component.version.to_i : nil
  end
  
  # return true if customer is license manager enabled (status 'a'), false for all other statuses
  def is_license_manager_enabled?
    (self.licensing_status == @@MANAGER_ENABLED)
  end
  

  ##################################################################################
  ## get most recently delivered hosting enrollment rules for a given hosted server
  ##################################################################################
  def self.get_most_recent_hosting_enrollment_rule_delivery(hosted_server)
    if(!hosted_server.nil?)
      logger.info "hosted server id: #{hosted_server.id}"
      HostingEnrollmentRuleDelivery.find_by_sql(["select * from hosting_enrollment_rule_delivery where status = 'd' and target_sam_server_id = ? order by delivered desc limit 1",
                                                hosted_server.id])[0]
    end
  end

  ##################################################################
  ## get pending hosting enrollment rules for a given hosted server
  ##################################################################
  def self.get_pending_hosting_enrollment_rules(hosted_server)
    if(!hosted_server.nil?)
      HostingEnrollmentRuleDelivery.find_by_sql(["select * from hosting_enrollment_rule_delivery where status = 'p' and target_sam_server_id = ? limit 1",
                                                hosted_server.id])[0]
    end
  end

  ############################################################################
  ## creates a new pending hosting enrollment rules for a given hosted server
  ############################################################################
  def self.create_pending_hosting_enrollment_rules(hosted_server)
    # select the most recently created active entitlement for the customer to use as the source entitlement of the pending hosting enrollment rule
    most_recently_active_entitlement = Entitlement.find_by_sql(["select e.* from entitlement e, product p, product_group pg where e.product_id = p.id
                                                               and p.product_group_id = pg.id and sam_customer_id = ? and seats_active = 1
                                                               and pg.code in ('HOSTED', 'SITE', 'ULTD_HOSTING') order by created_at desc limit 1", hosted_server.sam_customer_id])[0]
    if(!most_recently_active_entitlement.nil?)
      HostingEnrollmentRuleDelivery.transaction do
        now = Time.now
        pending_rule = HostingEnrollmentRuleDelivery.new
        pending_rule.status = 'p'
        pending_rule.target_sam_server_id = hosted_server.id
        pending_rule.source_entitlement_id = most_recently_active_entitlement.id
        pending_rule.created = now
        pending_rule.save!
      end
      logger.info "Pending hosting enrollment rule created for server :#{hosted_server.id}"
      success = true
    else
      logger.info "No active entitlement selected for pending hosting enrollment rules"
      success = false
    end
  end
  
  def self.get_landscape_view(sam_customer_id, subcommunities)
    landscape_records = landscape_records(sam_customer_id)
    landscape_view = {}
    #subcommunities = {}
    landscape_records.each do |lr|
      landscape_view[lr.sam_server_id] = {} if landscape_view[lr.sam_server_id].nil?
      landscape_view[lr.sam_server_id][lr.subcommunity_id] = lr
      subcommunities[lr.subcommunity_id] = lr.subcommunity_code
    end
    return landscape_view
  end
  
  # (sam_server_id, sam_server_name, subcommunity_id, subcommunity_code, seat_count, enrolled_count)
  def self.landscape_records(sam_customer_id)
    SeatPool.find(:all, :select => "ss.id as sam_server_id, ss.name as sam_server_name, s.id as subcommunity_id, s.code as subcommunity_code, sp.seat_count, sssi.used_seats as enrolled_count",
                    :joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id 
                                inner join subcommunity s on sp.subcommunity_id = s.id 
                                inner join sam_server_community_info ssci on ssci.sam_server_id = ss.id 
                                inner join sam_server_subcommunity_info sssi on sssi.sam_server_community_info_id = ssci.id",
                    :conditions => ["sp.sam_customer_id = ? and ss.status = 'a' and sssi.subcommunity_id = s.id", sam_customer_id],
                    :order => "ss.id, s.id")
  end
  
  
  def self.get_landscape_schools_view(sam_customer_id, subcommunities)
    landscape_records = SamServerSchoolEnrollment.find(:all, :select => "sssi.id as school_id, sssi.name as school_name, ss.id as sam_server_id, ss.name as sam_server_name, 
                    s.id as subcommunity_id, s.code as subcommunity_code, ssse.allowed_max as seat_count, ssse.enrolled as enrolled_count",
                    :joins => "ssse inner join sam_server_school_info sssi on ssse.sam_server_school_info_id = sssi.id
                                inner join sam_server ss on sssi.sam_server_id = ss.id
                                inner join subcommunity s on ssse.subcommunity_id = s.id",
                    :conditions => ["ss.sam_customer_id = ? and ss.status = 'a'", sam_customer_id],
                    :order => "sssi.name")
    landscape_view = {}
    #subcommunities = {}
    landscape_records.each do |lr|
      landscape_view[lr.school_id] = {} if landscape_view[lr.school_id].nil?
      landscape_view[lr.school_id][lr.subcommunity_id] = lr
      subcommunities[lr.subcommunity_id] = lr.subcommunity_code
    end
    return landscape_view
  end
  
  def total_enrollment_count(subcommunity_id)
    SamServerSubcommunityInfo.sum("sssi.used_seats", :joins => "sssi inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id
                                                                inner join sam_server ss on ssci.sam_server_id = ss.id
                                                                inner join sam_customer sc on ss.sam_customer_id = sc.id",
                                                      :conditions => ["sc.id = ? and sssi.subcommunity_id = ? and ss.status = 'a'", self.id, subcommunity_id])
  end
  
  def self.out_of_compliance_counts(sort_by_param)
    Task.find_by_sql("select distinct sc.id as sam_customer_id, sc.name as sam_customer_name, s.name as product_name, abs(sum(tp3.value)) as out_of_compliance_count 
    from tasks t inner join task_types tt on t.task_type_id = tt.id
    inner join task_params tp on (tp.task_id = t.id and tp.name = 'subcommunityId')
    inner join task_params tp2 on (tp2.task_id = t.id and tp2.name = 'reason' and tp2.value = 'LSE')
    inner join task_params tp3 on (tp3.task_id = t.id and tp3.name = 'delta')
    inner join subcommunity s on tp.value = s.id
    inner join sam_customer sc on t.sam_customer_id = sc.id
    where tt.code = 'PLCC' and t.status != 'c' group by sam_customer_id, tp.value order by " + sort_by_param)
  end
  
    # Purpose: Determine if a customer has requested license activation and is awaiting approval or denial from
  #          customer service.
  # Details: After a customer requests license activation, a customer service task is created. Pending-Activation
  #          status is determined by checking for an open customer service licensing-activiation task.
  #          An approved customer will have licensing_status = "a" (activated); a denied request will close the task and
  #          leave the licensings_status as "n" (not activated).
  #
  def is_awaiting_license_manager_approval?
    scla_task_type = TaskType.find_by_code("SCLA")
    isAwaitingApproval = !(Task.find(:first, :conditions =>
      ["task_type_id = ? and status != ? and sam_customer_id = ?", scla_task_type.id, 'c', self.id]).nil?)
    return isAwaitingApproval
  end
  
  # the License Manager versions that we allow users to switch to. locking down this way requires code update when new
  # LM versions come out, but seems preferable to allowing freeform input.
  # @available_license_manager_versions is used only for straightforward allowed changes of LM version.
  #   - customer can't simply change to or from version 1 -- other process for that.
  #   - if customer has no current LM version at all, this is not the way to opt them in -- other process for that.
  def get_available_license_manager_versions
    available_license_manager_versions = [ ]
    if self.license_manager_version == 1
      available_license_manager_versions = [ ['1', 1] ]
    elsif self.license_manager_version
      available_license_manager_versions = [ ['2', 2], ['3', 3], ['4', 4], ['5', 5] ]
    end
    
    return available_license_manager_versions
  end
  
  def hosted_out_of_compliance_count(product)
    
  end
  
  def license_count_problems?
	lcd_task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_DISCREPANCY_CODE)
	lcip_task_type = TaskType.find_by_code(TaskType.LICENSE_COUNT_INTEGRITY_PROBLEM_CODE)
	!(Task.find(:all, :conditions => ["sam_customer_id = ? and task_type_id in (?,?) and status != 'c'", self.id, lcd_task_type.id, lcip_task_type.id]).empty?)
  end

	def license_count_issues?
		plcc_task_type = TaskType.find_by_code(TaskType.PENDING_LICENSE_COUNT_CHANGE_CODE)
		self.license_count_problems? || !(Task.find(:first, :conditions => ["sam_customer_id = ? and task_type_id = ? and status != 'c'", self.id, plcc_task_type.id]).nil?)
	end
  
  def unregistered_pool(subcommunity_id)
	SeatPool.find(:first, :select => "sp.*", :joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id", :conditions => ["sp.sam_customer_id = ? and ss.server_type = ? and sp.subcommunity_id = ?", 
					self.id, SamServer.TYPE_UNREGISTERED_GENERIC, subcommunity_id])
  end
  
  def customer_admins
    self.users.select{|u| u.isCustomerType && u.active}
  end
  
  def self.find_number_of_problematic_servers(sam_customer_id)
    find_by_sql(["select count(a.id) as the_count from sam_server ss inner join agent a on a.sam_server_id = ss.id
                  where ss.sam_customer_id = ? and ss.status = 'a' and time_to_sec(timediff(now(),a.next_poll_at)) > 86400", sam_customer_id])[0].the_count
  end

  def self.find_number_of_servers_with_atleast_one_src_quiz_preference(sam_customer_id)
    find_by_sql(["select count(ss.id) as the_count from sam_server ss inner join src_quiz_preferences sqp on sqp.sam_server_id = ss.id
                  where ss.sam_customer_id = ? and ss.status = 'a' and (sqp.src_quiz_01 = 1 or sqp.src_quiz_02 = 1 or sqp.src_quiz_03 = 1 or sqp.src_quiz_04 = 1 or sqp.src_quiz_05 = 1)", sam_customer_id])[0].the_count
  end
  
  def self.find_registered
  	find(:all, :select => "trim(sc.name) as sam_customer_name, count(a.id) as problematic_agent_count, sc.id as sam_customer_id, 
                           sc.registration_date, count(ss.id) as sam_server_count, (100 - round((count(a.id) / count(ss.id) * 100))) as connectivity,
                           ca.address_line_1, ca.city_name, sp.code as state_code, ca.postal_code, ca.zip_code",
  		:joins => "sc inner join org on sc.root_org_id = org.id 
  				inner join customer c on org.customer_id = c.id
  				inner join customer_address ca on ca.customer_id = c.id
  				inner join state_province sp on ca.state_province_id = sp.id
  				inner join address_type atype on ca.address_type_id = atype.id
          inner join sam_server ss on ss.sam_customer_id = sc.id
          left join agent a on (a.sam_server_id = ss.id and (time_to_sec(timediff(now(),a.next_poll_at)) > 86400))",
  		:conditions => ["sc.registration_date is not null and atype.code = ? and sc.fake = false", AddressType.MAILING_CODE],
      :group => "sc.id", :order => "sp.code")
  end
  
  def state
    SamCustomer.find_by_sql(["select sp.* from sam_customer sc
                              inner join org on sc.root_org_id = org.id
                              inner join customer c on org.customer_id = c.id
                              inner join customer_address ca on ca.customer_id = c.id
                              inner join state_province sp on ca.state_province_id = sp.id
                              where sc.id = ? limit 1", self.id])[0]
  end
  
  def ucn=(ucn)
    self.root_org = Org.find_by_ucn(ucn)
  end
  
  def use_default_name=(use_default_name)
  end
  
  def use_default_name
  end
  
  def org_name
    self.root_org.name.strip
  end
  
  def newest_sam_server
    SamServer.find(:first, :conditions => ["sam_customer_id = ?", self.id], :order => "created_at desc")
  end
  
  def number_of_active_sam_servers
  	SamServer.count(:conditions => ["sam_customer_id = ? and status = 'a' and server_type in (?,?)", self.id, SamServer.TYPE_LOCAL, SamServer.TYPE_HOSTED])
  end
  
  def number_of_sam_servers
    SamServer.count(:conditions => ["sam_customer_id = ?", self.id])
  end
  
  def number_of_active_hosted_sam_servers
    SamServer.count(:conditions => ["sam_customer_id = ? and status = 'a' and server_type = ?", self.id, SamServer.TYPE_HOSTED])
  end
  
  def number_of_entitlements
    Entitlement.count(:conditions => ["sam_customer_id = ?", self.id])
  end
  
  def get_hosted_server
	SamServer.find(:first, :conditions => ["sam_customer_id = ? and status = 'a' and server_type = ?", self.id, SamServer.TYPE_HOSTED])
  end

  def is_dashboard_export_blacklisted
    my_ucn = self.ucn
    if my_ucn.nil? 
      return nil
    else 
      blacklist_count = ConvExportBlacklistByUcn.find_by_sql(["SELECT count(1) as the_count FROM scholastic.conv_export_blacklist_by_ucn c where c.ucn = ?", my_ucn])[0].the_count
      return blacklist_count == "0" ? false : true;
    end
  end
  
  def self.find_by_ucn(ucn)
    org = Org.find_by_ucn(ucn)
    return org.sam_customer if !org.nil?
    return nil
  end
  
  def self.find_ucn_by_sam_customer_id(id)
    sam_customer = SamCustomer.first(:all, :conditions => ["id = ?", id])
  end  
  
  def self.find_by_keystring(keystring)
    results = find(:all, :select => "distinct sc.*, c.ucn as sc_ucn, org.id as org_id, sp.name as state_name, si.description",
         :joins => "sc inner join org on sc.root_org_id = org.id
                    inner join customer c on org.customer_id = c.id
                    inner join customer_address ca on (ca.customer_id = c.id and ca.address_type_id = 5)
                    inner join scholastic_index si on sc.scholastic_index_id = si.id
                    left join state_province sp on ca.state_province_id = sp.id", 
         :conditions => ["sc.id = ?", keystring], :order => "sp.name, sc.name")
    if (results.empty?)
      fillin = "%" + keystring + "%"
      results = find(:all, :select => "distinct sc.*, c.ucn as sc_ucn, org.id as org_id, sp.name as state_name, si.description",
           :joins => "sc inner join org on sc.root_org_id = org.id
                      inner join customer c on org.customer_id = c.id
                      inner join customer_address ca on (ca.customer_id = c.id and ca.address_type_id = 5)
                      inner join scholastic_index si on sc.scholastic_index_id = si.id
                      left join state_province sp on ca.state_province_id = sp.id", 
           :conditions => ["sc.name like ?", fillin], :order => "sp.name, sc.name")
    end
    return results
  end
  
  
  def self.search(params, limit=-1, sortby="sp.name, sc.name") #ordering by state then customer name to follow pre-existing functionality
  	select_clause = "distinct sc.id, sc.name, sc.siteid, sc.registration_date, sc.active, sc.fake, sc.update_quiz_as_available, c.ucn as sc_ucn, org.id as org_id, si.description as si_description, 
                      sp.name as state_name, sp.code as state_code, ca.address_line_1, ca.city_name, ca.zip_code,
                      sc.licensing_status, sc.auth_status, sc.update_manager_status, sc.update_quiz_as_available "
  	joins_clause = "sc inner join org on sc.root_org_id = org.id
          inner join customer c on org.customer_id = c.id
  				inner join customer_address ca on c.id = ca.customer_id
  				inner join state_province sp on ca.state_province_id = sp.id
          inner join scholastic_index si on sc.scholastic_index_id = si.id 
          inner join sam_server ss on ss.sam_customer_id = sc.id "
    community_1_included = false
    community_2_included = false
  	mailing_type = AddressType.find_by_code(AddressType.MAILING_CODE)
  	conditions_clause = "ca.address_type_id = ? "
  	conditions_clause_fillins = []
  	conditions_clause_fillins << mailing_type.id
  	#order_clause = "sp.name, sc.name"
  	if (params[:ucn] && !params[:ucn].empty?)
  	  conditions_clause += "and c.ucn = ? "
  	  conditions_clause_fillins << params[:ucn]
  	elsif (params[:sam_customer_id] && !params[:sam_customer_id].empty?)
  		conditions_clause += "and sc.id = ? "
      conditions_clause_fillins << params[:sam_customer_id]
    end
    if (params[:siteid] && !params[:siteid].empty?)
      conditions_clause += "and siteid = ? "
      conditions_clause_fillins << params[:siteid]
    end
  	if (params[:state_province_id] && !params[:state_province_id].empty?)
  		conditions_clause += "and sp.id = ? "
  		conditions_clause_fillins << params[:state_province_id] 
    end
    if (params[:active] == "1")
      conditions_clause += "and sc.active = true "
    elsif (params[:active] == "2")
      conditions_clause += "and sc.active = false "
    end
    if (params[:fake] == "1")
      conditions_clause += "and sc.fake = true "
    elsif (params[:fake] == "2")
      conditions_clause += "and sc.fake = false "
    end
    if (params[:is_hosted] == 1 && !params[:is_hosted].empty?)
        conditions_clause += "and ss.status = 'a' and ss.server_type = ?"
        conditions_clause_fillins << params[:is_hosted]
    end
    if (params[:registered_at_start_date] && !params[:registered_at_start_date].strip.empty?)
      conditions_clause += "and sc.registration_date >= '#{params[:registered_at_start_date]} #{params[:registered_at_start_time]}'"
      #conditions_clause_fillins << params[:registered_at_start_date] << params[:registered_at_start_time] 
    end
  	if (params[:zip_code] && !params[:zip_code].strip.empty?)
  		conditions_clause += "and ca.zip_code = ? "
  		conditions_clause_fillins << params[:zip_code].to_i 
  	end
  	if (params[:name] && !params[:name].strip.empty?)
  		conditions_clause += "and sc.name like ? "
  		conditions_clause_fillins << ("%" + params[:name] + "%")
    end
    if (params[:product_id] && !params[:product_id].empty?)
      joins_clause += "inner join entitlement e on e.sam_customer_id = sc.id"
      conditions_clause += "and e.product_id = ? "
      conditions_clause_fillins << params[:product_id]
    end
    if (params[:community_name1] && !params[:community_name1].empty?)
      community_1_included = true
      joins_clause += "inner join sam_server ss1 on ss1.sam_customer_id = sc.id "
      joins_clause += "inner join sam_server_community_info ssci1 on ssci1.sam_server_id = ss1.id "
      conditions_clause += "and ssci1.community_id = ? "
      conditions_clause_fillins << params[:community_name1]
    end
    if (community_1_included && params[:community_min_version1] && !params[:community_min_version1].empty?)
      conditions_clause += "and ssci1.version >= ? "
      conditions_clause_fillins << params[:community_min_version1]
    end
    if (params[:community_name2] && !params[:community_name2].empty?)
      community_2_included = true
      joins_clause += "inner join sam_server ss2 on ss2.sam_customer_id = sc.id "
      joins_clause += "inner join sam_server_community_info ssci2 on ssci2.sam_server_id = ss2.id "
      conditions_clause += "and ssci2.community_id = ? "
      conditions_clause_fillins << params[:community_name2]
    end
  	if (community_2_included && params[:community_min_version2] && !params[:community_min_version2].empty?)
      conditions_clause += "and ssci2.version <= ? "
      conditions_clause_fillins << params[:community_min_version2]
    end
    if (params[:lm_certified] && params[:lm_certified] == "1")
      conditions_clause += "and sc.licensing_certified = true "
    end
    if (params[:lm_enabled] && params[:lm_enabled] == "1")
      conditions_clause += "and sc.sc_licensing_activated is not null "
    end
    if (params[:sum_enabled] && params[:sum_enabled] == "1")
      conditions_clause += "and sc.update_manager_activated is not null "
    end
    if (params[:am_enabled] && params[:am_enabled] == "1")
      conditions_clause += "and sc.auth_activated is not null "
    end
    if (params[:uqaa] == "1")
      conditions_clause += "and sc.update_quiz_as_available = true "
    elsif (params[:uqaa] == "2")
      conditions_clause += "and sc.update_quiz_as_available = false "
    end
  	
  	if(limit > 0)
      find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => sortby, :limit => limit)
    else #negative value of limit indicates no limit
      find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => sortby)
    end
  end
  
  # Builds an array of objects, each of which contains a subcommunity and the seat counts from various SAM Connect sources:  entitlements, seat pool, and sam server subcommunity info
  # If 'entitlement_date' is not nil, the method also calculates the sum of counts from virtual entitlements that were added after 'entitlement_date'
  # each element in the array returned contains the following properties:  
  #   - pool_count = the count of allocated licenses according to the seat pool
  #   - server count = the count of allocated licenses according to the sam_server_subcommunity_info records
  #   - unallocated_count = the count of unallocated licenses according to the seat pool
  #   - entitlement_count = the count from entitlements
  #   - virtual_count = the count from virtual entitlements that were added after 'entitlement_date'
  #def build_seat_count_profile(entitlement_date)  
  #  pool_and_server_counts = self.total_sssi_licenses_by_subcommunity(nil)
  #  license_count_comparisons = self.total_unalloc_pool_end_entitlement_count_by_subcom
  #  server_subcom_ids = pool_and_server_counts.collect {|i| i.id }
  #  if (entitlement_date)
  #    virtual_counts = self.virtual_entitlement_counts(entitlement_date, nil)
  #    virt_subcom_ids = virtual_counts.collect {|i| i.id}
  #    license_count_comparisons.each do |lcc|
  #      if (subcom_index = server_subcom_ids.index(lcc.id))
  #        pool_and_server_count = pool_and_server_counts[subcom_index]
  #        pool_count = pool_and_server_count.pool_count
  #        server_count = pool_and_server_count.server_count
  #        lcc.pool_count = pool_count
  #        lcc.server_count = server_count
  #        if (virt_subcom_index = virt_subcom_ids.index(lcc.id))
  #          lcc.virtual_count = virtual_counts[virt_subcom_index].virtual_count
  #        end
  #      end
  #    end
  #  else
  #    license_count_comparisons.each do |lcc|
  #      if (subcom_index = server_subcom_ids.index(lcc.id))
  #        pool_and_server_count = pool_and_server_counts[subcom_index]
  #        pool_count = pool_and_server_count.pool_count
  #        server_count = pool_and_server_count.server_count
  #        lcc.pool_count = pool_count
  #        lcc.server_count = server_count
  #      end
  #    end
  #  end
  #  license_count_comparisons.sort! {|a,b| a.name <=> b.name}
  #  return license_count_comparisons
  #end
  
  def virtual_entitlement_counts(entitlement_date, subcommunity_id)
    if (subcommunity_id)
      subcommunity = Subcommunity.find(subcommunity_id)
      count = Entitlement.find_by_sql(["select s.id, sum(license_count) as virtual_count from entitlement e
                inner join product p on e.product_id = p.id
                inner join subcommunity s on s.product_id = p.id
                where e.created_at > ? and e.sc_entitlement_type_id = ? and e.sam_customer_id = ? and e.product_id = ?
                group by s.id", entitlement_date.to_s, ScEntitlementType.virtual.id, self.id, subcommunity.product.id])
      (count[0]) ? count[0].virtual_count : 0
    else
      Entitlement.find_by_sql(["select s.id, sum(license_count) as virtual_count from entitlement e
                inner join product p on e.product_id = p.id
                inner join subcommunity s on s.product_id = p.id
                where e.created_at > ? and e.sc_entitlement_type_id = ? and e.sam_customer_id = ?
                group by s.id", entitlement_date.strftime("%Y-%m-%d %H:%M:%S"), ScEntitlementType.virtual.id, self.id])
    end
  end
  
  # JEFF --> Remove this comment when your done.  I renamed list to better match to the tables they come from.  Change
  # anything, but if you need to change "active_subcommunities", talk to me first. (Bob)
  
  # Subcommunities
  # --------------
  # Examples to highlight differences in subcommunity lists
  #
  # Example: 
  #   A customer bought one product from Scholastic, READ 180 Stage A.  They installed R180 (e.g., the community)
  #   to their one server.  In addition, they are sampling a free trial FasttMath, but have -not- installed 
  #   FasttMath yet.  The READ 180 Stage A is a TMS entitment, FasttMath is a virtual entitlment (this makes no
  #   difference in these lists, but highlight the fact that it makes not differnce).
  #      * active_subcommunities   = R180 Stage A, FasttMath
  #      * installed_subcommunites = R180 Stage A  (no FasttMath)
  #      * entitled_subcommunities - R180 Stage A, FasttMath
  
  
  # List of subcommunities that a customer is actively using (via the Seat Pool table).  
    def active_subcommunities
      if self.sc_licensing_activated.nil?
       # TODO: Get list from sam_server_subcommunity_info table (since seat_pool will not be populated yet)
      else
       (self.seat_pools).collect{|sp| sp.subcommunity}.uniq.sort! {|a,b| a.name <=> b.name}
      end
  end
  
  # Jeff, do we need one like this for your balancing stuff: 
  # List of subcommunities entitled-to (owned) by a customer; the Entitlement view of subcommunities.
  def entitled_subcommunities
     (self.entitlements).collect {|e| e.product.subcommuity}.uniq.sort! {|a,b| a.name <=> b.name}
  end

  # Communities are installed, and hence, by definition, all subcommunities of a community are installed. 
  # List of all subcommunities installed on a customers active sam servers
  def installed_subcommunities
    # tbd 
  end
  
  # Jeff --> All yours
  def Jeffs_balancing_needed_method
    #call active_subcommunities, entitled_subcommunities, and installed_subcommunities from here
    #example:  self.entitled_subcommunities ......
  end
  
  def unregistered_generic_server
	  SamServer.find(:first, :conditions => ["server_type = 2 and sam_customer_id = ?", self.id])
  end
  
  def available_subcommunities
    #licensed_subcommunities = Subcommunity.find_by_sql(["select distinct s.* from sam_customer as sc
    #                         inner join sam_server as ss on ss.sam_customer_id = sc.id
    #                         inner join sam_server_community_info as ssci on ssci.sam_server_id = ss.id
    #                         inner join sam_server_subcommunity_info as sssi on sssi.sam_server_community_info_id = ssci.id
    #                         inner join subcommunity as s on sssi.subcommunity_id = s.id where sc.id = ? and ss.status = 'a'", self.id]).uniq
    #ordered_subcommunities = Subcommunity.find_by_sql(["select distinct s.* from sam_customer as sc
    #                        inner join entitlement e on e.sam_customer_id = sc.id
    #                        inner join product p on e.product_id = p.id
    #                        inner join subcommunity s on s.product_id = p.id
    #                        where sc.id = ? and e.seats_active = true", self.id]).uniq
    Subcommunity.find_by_sql(["select distinct s.* from sam_customer sc inner join seat_pool sp on sp.sam_customer_id = sc.id 
      inner join subcommunity s on sp.subcommunity_id = s.id left join sam_server ss on (sp.sam_server_id = ss.id and ss.status = 'a') where sc.id = ?", self.id])
    #remove rSkills from the list
    #licensed_subcommunities.concat(ordered_subcommunities).uniq.reject {|subcom| subcom == Subcommunity.find_by_code("RT")}.sort {|a,b| a.name <=> b.name}    
  end
  
  def total_sssi_licenses(subcom)
    SamCustomer.find_by_sql(["select sum(sssi.licensed_seats) as total_count from sam_customer as sc
                             inner join sam_server as ss on ss.sam_customer_id = sc.id
                             inner join sam_server_community_info as ssci on ssci.sam_server_id = ss.id
                             inner join sam_server_subcommunity_info as sssi on sssi.sam_server_community_info_id = ssci.id
                             where ss.status = 'a' and sssi.subcommunity_id = ? and sc.id = ?", subcom.id, self.id])[0].total_count
  end
  
  def total_sssi_licenses_by_subcommunity(subcommunity_id)
    if (subcommunity_id)
      SamServerSubcommunityInfo.find_by_sql(["select subcom.id, ifnull(sum(sssi.licensed_seats),0) as server_count,
              ifnull(sum(sp.seat_count),0) as pool_count from sam_server_subcommunity_info sssi
              inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id
              inner join sam_server ss on ssci.sam_server_id = ss.id
              inner join sam_customer sc on ss.sam_customer_id = sc.id
              inner join subcommunity subcom on sssi.subcommunity_id = subcom.id
              left join seat_pool sp on (sp.sam_customer_id = sc.id and sp.sam_server_id = ss.id and sp.subcommunity_id = subcom.id)
              where sc.id = ? and subcom.id = ? and ss.status = 'a' and subcom.code != 'RT' group by sssi.subcommunity_id", self.id, subcommunity_id])[0]
    else
      SamServerSubcommunityInfo.find_by_sql(["select subcom.id, ifnull(sum(sssi.licensed_seats),0) as server_count,
              ifnull(sum(sp.seat_count),0) as pool_count from sam_server_subcommunity_info sssi
              inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id
              inner join sam_server ss on ssci.sam_server_id = ss.id
              inner join sam_customer sc on ss.sam_customer_id = sc.id
              inner join subcommunity subcom on sssi.subcommunity_id = subcom.id
              left join seat_pool sp on (sp.sam_customer_id = sc.id and sp.sam_server_id = ss.id and sp.subcommunity_id = subcom.id)
              where sc.id = ? and ss.status = 'a' and subcom.code != 'RT' group by sssi.subcommunity_id", self.id])
    end
  end
  
  def total_unalloc_pool_count_by_subcom
    SeatPool.find_by_sql(["select subcom.id, subcom.name, sum(sp.seat_count) as unallocated_count, (0) as pool_count, (0) as server_count from seat_pool sp
                inner join subcommunity subcom on sp.subcommunity_id = subcom.id
                where sp.sam_server_id is null and sam_customer_id = ? and subcom.code != 'RT' group by subcom.id", self.id])
  end
  
  def total_unalloc_pool_end_entitlement_count_by_subcom
    SeatPool.find_by_sql(["select distinct(sp.seat_count) as unallocated_count, subcom.id, subcom.name, (0) as virtual_count, (0) as pool_count, (0) as server_count, ifnull(sum(e.license_count),0) as entitlement_count from seat_pool sp
                           inner join subcommunity subcom on sp.subcommunity_id = subcom.id
                           inner join product p on subcom.product_id = p.id
                           left join entitlement e on (e.product_id = p.id and e.sam_customer_id = sp.sam_customer_id)
                           where sp.sam_server_id is null and sp.sam_customer_id = ? and subcom.code != 'RT' group by subcom.id", self.id])
  end
  
  def pending_successful_seat_activities?(subcom)
    seat_pools_for_subcom = SeatPool.find_all_by_sam_customer_id_and_subcommunity_id(self.id, subcom.id)
    seat_pools_for_subcom.each do |spfs|
    last_successful_seat_activity = SeatActivity.find(:first, 
                                        :joins => "inner join conversation_instance on seat_activity.conversation_instance_id = conversation_instance.id",
                                        :conditions => ["seat_activity.status = 1 and conversation_instance.result_type_id = ?", ConversationResultType.find_by_code("S")],
                                        :order => "seat_activity.id desc")
      
    end
  end
  
  ##############################
  # SUBCOMMUNITY SCALE QUERIES #
  ##############################
  
  # the total count from entitlements
  def entitlement_count(subcommunity_id)
    Entitlement.find_by_sql(["select ifnull(sum(e.license_count),0) as entitlement_count from entitlement e
      inner join product p on e.product_id = p.id
      inner join subcommunity s on s.product_id = p.id
      where e.sam_customer_id = ? and s.id = ? and e.seats_active = true", self.id, subcommunity_id])[0].entitlement_count.to_i
  end
  
  
  # the total seat pool count
  def seat_pool_count(subcommunity_id)
	  subcommunity = Subcommunity.find(subcommunity_id)
	  self.unallocated_pool_count(subcommunity).to_i + self.allocated_pool_count(subcommunity_id).to_i
  end
  
  # the total allocated count from the seat pool
  def allocated_pool_count(subcommunity_id)
    SeatPool.find_by_sql(["select ifnull(sum(sp.seat_count),0) as allocated_pool_count from seat_pool sp 
                inner join sam_server ss on sp.sam_server_id = ss.id where ss.status = 'a' and 
                sp.sam_customer_id = ? and sp.subcommunity_id = ?", self.id, subcommunity_id])[0].allocated_pool_count
  end
  
  def net_plcc_count(subcommunity_id)
    plcc_task_type = TaskType.find_by_code("PLCC")
    Task.find_by_sql(["select ifnull(sum(convert(tp_delta.value,decimal)),0) as net_count from tasks t inner join task_params tp_subcom on (tp_subcom.task_id = t.id and tp_subcom.name = 'subcommunityId'
            and tp_subcom.value = ?) inner join task_params tp_delta on (tp_delta.task_id = t.id and tp_delta.name = 'delta')
            where t.task_type_id = ? and t.sam_customer_id = ? and t.status not in (?, ?)", subcommunity_id, plcc_task_type.id, self.id, Task.CLOSED, Task.OBSOLETE])[0].net_count.to_i
  end
  
  def max_seats_on_hosted_servers(subcommunity)
	  (self.hosted_total_active_subscription_count(subcommunity) + self.total_active_subscription_licenses(subcommunity))
  end
  
  
  def max_seats_on_local_servers(subcommunity)
	  #Subcommunity.sum("e.license_count", 
		#	:joins => "s inner join product p on s.product_id = p.id
		#				inner join entitlement e on e.product_id = p.id", 
		#	:conditions => ["e.sam_customer_id = ? and s.id = ? and e.subscription_start is null", self.id, subcommunity.id]).to_i
      # first get the number of non-subscription based licenses
  	  count_based_on_perpetual_licenses = Subcommunity.sum("e.license_count", 
  			:joins => "s inner join product p on s.product_id = p.id
  						inner join entitlement e on e.product_id = p.id", 
  			:conditions => ["e.sam_customer_id = ? and s.id = ? and e.subscription_start is null", self.id, subcommunity.id]).to_i
  	  # now add in the number of licenses that were converted to this product (if any)
  	  product = subcommunity.product
  	  conversion_product_map = product.post_entry_in_conversion_product_map
  	  if (!conversion_product_map.nil?)
  	    conversion_product = conversion_product_map.product
  	    conversion_license_pool = ConversionLicense.find(:first, :conditions => ["sam_customer_id = ? and product_id = ?", self.id, conversion_product.id])
  	    # if some licenses were converted to this product
  	    if (!conversion_license_pool.nil?)
  	      count_based_on_perpetual_licenses += conversion_license_pool.converted_count
  	    end
  	  end
  	  logger.info("count_based_on_perpetual_licenses: #{count_based_on_perpetual_licenses.to_yaml}")
  	  # now subtract the number of licenses that were converted from this product (if any)
  	  conversion_product_map = product.pre_entry_in_conversion_product_map
  	  if (!conversion_product_map.nil?)
  	    conversion_product = conversion_product_map.product
  	    conversion_license_pool = ConversionLicense.find(:first, :conditions => ["sam_customer_id = ? and product_id = ?", self.id, conversion_product.id])
  	    # if some licenses were converted to this product
  	    if (!conversion_license_pool.nil?)
  	      count_based_on_perpetual_licenses -= conversion_license_pool.converted_count
  	    end
  	  end
  	  return count_based_on_perpetual_licenses
  end
  
  
  def local_allocated_count(subcommunity)
	  SeatPool.sum("sp.seat_count", 
			:joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id", 
			:conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and ss.server_type = 0 and ss.status = 'a'", self.id, subcommunity.id]).to_i
  end
  
  # the unallocated count from the seat pool
  def unallocated_pool_count(subcommunity)
    sp = SeatPool.find_seat_pool(self, subcommunity, nil)
    sp.nil? ? 0 : sp.seat_count
  end
  
  def unregistered_pool_count(subcommunity_id)
	SeatPool.find_by_sql(["select ifnull(sum(sp.seat_count), 0) as unregistered_seat_count from seat_pool sp 
                inner join sam_server ss on sp.sam_server_id = ss.id where  
                sp.sam_customer_id = ? and sp.subcommunity_id = ? and ss.server_type = ?", self.id, subcommunity_id, SamServer.TYPE_UNREGISTERED_GENERIC])[0].unregistered_seat_count
  end
  
  def hosted_total_active_subscription_count(subcommunity)
	hosted_product = subcommunity.product.hosted_product
	Subcommunity.sum("e.license_count", 
			:joins => "s inner join product p on s.product_id = p.id 
						inner join product hp on p.hosted_product_id = hp.id
						inner join entitlement e on e.product_id = hp.id", 
			:conditions => ["e.sam_customer_id = ? and s.id = ? and e.seats_active = true", self.id, subcommunity.id]).to_i
  end
  
  def hosted_total_active_subscription_counts
	Product.find(:all, :select => "hp.id as hosted_product_id, hp.description, ifnull(sum(e.license_count),0) as total_active_count, 0 as total_allocated_count", 
					:joins => "hp inner join entitlement e on e.product_id = hp.id
					            inner join product_group pg on hp.product_group_id = pg.id",
					:conditions => ["e.sam_customer_id = ? and pg.code = ? and e.seats_active = true", self.id, ProductGroup::HOSTED_CODE],
					:group => "hp.id")
  end
  
  def hosted_products_with_active_subscriptions
    Product.find(:all, :select => "distinct p.*", :joins => "p inner join entitlement e on e.product_id = p.id inner join product_group pg on p.product_group_id = pg.id",
          :conditions => ["e.sam_customer_id = ? and pg.code = ? and e.seats_active = true", self.id, ProductGroup::HOSTED_CODE])
  end
  
  def hosted_products_on_hosted_servers
    Product.find(:all, :select => "distinct hp.*", :joins => "p inner join subcommunity s on s.product_id = p.id
                          inner join seat_pool sp on sp.subcommunity_id = s.id
                          inner join sam_server ss on sp.sam_server_id = ss.id
                          inner join sam_customer sc on sp.sam_customer_id = sc.id
                          inner join product hp on p.hosted_product_id = hp.id",
                  :conditions => ["sc.id = ? and ss.server_type = ? and ss.status = 'a'", self.id, SamServer::TYPE_HOSTED])
  end
  
  def hosted_compliance_counts
      hosted_compliances = {}
      # first get the products that have active hosted subscriptions
      active_hosted_products = self.hosted_products_with_active_subscriptions
      active_hosted_products = active_hosted_products.concat(self.hosted_products_on_hosted_servers).uniq
      logger.info("active_hosted_products: #{active_hosted_products.to_yaml}")
      active_hosted_products.each do |ahp|
        # WARNING:  THIS NEXT LINE IS A TOTAL HACK!!!  DESIGN CONSIDERATIONS NEED TO BE ADDRESSED TO SUPPORT SUBSCRIPTIONS FOR MULTIPLE PRODUCTS IN A SINGLE GROUP!!
        product_hosted = ahp.products_hosted[0]
        logger.info("processing hosted product id #{ahp.hosted_product_id}")
        hosted_compliances[ahp.id] = ComplianceCountSet.new if hosted_compliances[ahp.id].nil?
        hosted_compliances[ahp.id].description = ahp.description
        allocated_subscription_counts = self.hosted_allocated_subscription_counts(ahp)
        if (!allocated_subscription_counts.empty? && !allocated_subscription_counts[0].total_allocated_count.nil?)
          hosted_compliances[ahp.id].total_allocated_count = allocated_subscription_counts[0].total_allocated_count
        end
        hosted_compliances[ahp.id].max_allowed_on_hosted_servers = self.max_seats_on_hosted_servers(product_hosted.subcommunity)
      end
      logger.info("hosted_compliances: #{hosted_compliances.to_yaml}")
            # 
            #     
            # hosted_active_counts = self.hosted_total_active_subscription_counts
            # logger.info("hosted_active_counts: #{hosted_active_counts.to_yaml}")
            # hosted_allocated_counts = SeatPool.find(:all, :select => "hp.id as hosted_product_id, hp.description, 0 as total_active_count, ifnull(sum(sp.seat_count),0) as total_allocated_count",
            #     :joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id
            #     inner join subcommunity s on sp.subcommunity_id = s.id
            #     inner join product p on s.product_id = p.id
            #     inner join product hp on p.hosted_product_id = hp.id",
            #     :conditions => ["sp.sam_customer_id = ? and ss.active = true and ss.server_type = 1", self.id],
            #     :group => "hp.id", :order => "hp.description")
            # hosted_counts = hosted_active_counts.concat(hosted_allocated_counts)
            # hosted_compliance_counts = {}
            # hosted_counts.each do |hc|
            #   logger.info("{Hosted Product ID: #{hc.hosted_product_id}; Product: #{hc.description}; Total Active: #{hc.total_active_count}; Total Allocated: #{hc.total_allocated_count}")
            #   hosted_compliance_counts[hc.hosted_product_id] = ComplianceCountSet.new if hosted_compliance_counts[hc.hosted_product_id].nil?
            #   hosted_compliance_counts[hc.hosted_product_id].description = hc.description
            #   logger.info("before active count: #{hosted_compliance_counts[hc.hosted_product_id].total_active_count}")
            #   hosted_compliance_counts[hc.hosted_product_id].total_active_count = hc.total_active_count if hc.total_active_count.to_i > 0
            #   logger.info("after active count: #{hosted_compliance_counts[hc.hosted_product_id].total_active_count}")
            #   hosted_compliance_counts[hc.hosted_product_id].total_allocated_count = hc.total_allocated_count if hc.total_allocated_count.to_i > 0
            #   logger.info("hash_entry: #{hosted_compliance_counts[hc.hosted_product_id].to_yaml}")
            # end
            #  logger.info("hosted compliance counts: #{hosted_compliance_counts.to_yaml}")
      return hosted_compliances
  end
  
  
    
    def e21_compliance_counts
        e21_group = ProductGroup.find_by_code("E21")
        e21_active_counts = Entitlement.find(:all, :select => "p.id, p.description, 0 as total_allocated_count, ifnull(sum(e.license_count),0) as total_active_count",
          :joins => "e inner join product p on e.product_id = p.id",
          :conditions => ["e.sam_customer_id = ? and p.product_group_id = ? and e.seats_active = true and p.sam_server_product = true", self.id, e21_group.id],
          :group => "p.id", :order => "p.id")
        e21_allocated_counts = SeatPool.find(:all, :select => "p.id, p.description, 0 as total_active_count, ifnull(sum(sp.seat_count),0) as total_allocated_count",
          :joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id
            inner join subcommunity s on sp.subcommunity_id = s.id
            inner join product p on s.product_id = p.id",
            :conditions => ["sp.sam_customer_id = ? and p.product_group_id = ? and ss.status = 'a' and ss.server_type = 1 and p.sam_server_product = true", self.id, e21_group.id],
            :group => "p.id", :order => "p.id")
        e21_counts = e21_active_counts.concat(e21_allocated_counts)
        e21_compliance_counts = {}
        e21_counts.each do |eac|
          logger.info("{Product: #{eac.description}; Total Active: #{eac.total_active_count}; Total Allocated: #{eac.total_allocated_count}")
          e21_compliance_counts[eac.id] = ComplianceCountSet.new if e21_compliance_counts[eac.id].nil?
          e21_compliance_counts[eac.id].description = eac.description
          e21_compliance_counts[eac.id].total_active_count = eac.total_active_count if eac.total_active_count.to_i > 0
          e21_compliance_counts[eac.id].max_allowed_on_hosted_servers = eac.total_active_count if eac.total_active_count.to_i > 0
          e21_compliance_counts[eac.id].total_allocated_count = eac.total_allocated_count if eac.total_allocated_count.to_i > 0
        end
        logger.info("e21 compliance counts: #{e21_compliance_counts.to_yaml}")
        return e21_compliance_counts
      end
  
  def hosted_allocated_subscription_count(subcommunity)
	  SeatPool.sum("sp.seat_count", 
			:joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id", 
			:conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and ss.server_type = 1", self.id, subcommunity.id]).to_i
  end
  
  def product_group_hosted_allocated_subscription_count(subcommunity)
	  hosted_product = subcommunity.product.hosted_product
  	total_count = 0
  	if (!hosted_product.nil?)
  	  products_being_hosted = hosted_product.products_hosted
    	products_being_hosted.each do |pbh|
    	  total_count += SeatPool.sum("sp.seat_count", 
      			:joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id", 
      			:conditions => ["sp.sam_customer_id = ? and sp.subcommunity_id = ? and ss.server_type = 1", self.id, pbh.subcommunity.id]).to_i
      end
    end
    return total_count
  end
  
  def hosted_allocated_subscription_counts(hosted_product = nil)
    if (hosted_product.nil?)
      SeatPool.find(:all, :select => "hp.id as hosted_product_id, hp.description, sum(sp.seat_count) as total_allocated_count",
        :joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id
                    inner join subcommunity s on sp.subcommunity_id = s.id
                    inner join product p on s.product_id = p.id
                    inner join product hp on p.hosted_product_id = hp.id",
        :conditions => ["sp.sam_customer_id = ? and ss.status = 'a' and ss.server_type = 1", self.id],
        :group => "hp.id")
    else
      SeatPool.find(:all, :select => "hp.id as hosted_product_id, hp.description, sum(sp.seat_count) as total_allocated_count",
        :joins => "sp inner join sam_server ss on sp.sam_server_id = ss.id
                    inner join subcommunity s on sp.subcommunity_id = s.id
                    inner join product p on s.product_id = p.id
                    inner join product hp on p.hosted_product_id = hp.id",
        :conditions => ["hp.id = ? and sp.sam_customer_id = ? and ss.status = 'a' and ss.server_type = 1", hosted_product.id, self.id])
    end
  end
  
  
  def total_active_subscription_licenses(subcommunity)
	Subcommunity.sum("e.license_count", 
			:joins => "s inner join product p on s.product_id = p.id
						inner join entitlement e on e.product_id = p.id", 
			:conditions => ["e.sam_customer_id = ? and s.id = ? and e.seats_active = true and e.subscription_start is not null and p.sam_server_product = true", self.id, subcommunity.id]).to_i
  end
  
  # Get the total server count from the sam_server_subcommunity_info records
  def server_count(subcommunity_id)
    SamServerSubcommunityInfo.find_by_sql(["select ifnull(sum(licensed_seats),0) as server_count from sam_server_subcommunity_info sssi
      inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id
      inner join sam_server ss on ssci.sam_server_id = ss.id
      where ss.sam_customer_id = ? and sssi.subcommunity_id = ? and ss.status = 'a'", self.id, subcommunity_id])[0].server_count
  end
  
  # the virtual entitlement count after a specific time
  def virtual_entitlement_count(subcommunity_id, entitlement_date = nil)
    if (!entitlement_date.nil?)
      Entitlement.find_by_sql(["select ifnull(sum(license_count),0) as virtual_entitlement_count from entitlement e
        inner join product p on e.product_id = p.id
        inner join subcommunity s on s.product_id = p.id
        where e.sc_entitlement_type_id IN (?, ?) and e.sam_customer_id = ?
        and s.id = ? and e.created_at > ?", ScEntitlementType.old_virtual.id, ScEntitlementType.virtual.id, self.id, subcommunity_id, entitlement_date.strftime("%Y-%m-%d %H:%M:%S")])[0].virtual_entitlement_count
    else
      Entitlement.find_by_sql(["select ifnull(sum(license_count),0) as virtual_entitlement_count from entitlement e
        inner join product p on e.product_id = p.id
        inner join subcommunity s on s.product_id = p.id
        where e.sc_entitlement_type_id IN (?, ?) and e.sam_customer_id = ?
        and s.id = ?", ScEntitlementType.old_virtual.id, ScEntitlementType.virtual.id, self.id, subcommunity_id])[0].virtual_entitlement_count
    end
  end
  
  def conversion_adjustment_count(subcommunity)
    conversion_adjustment = 0
    product = subcommunity.product
    conversion_product_map = ConversionProductMap.find(:first, :conditions => ["pre_converted_product_id = ?", product])
    if (!conversion_product_map.nil?)
      conversion_license_pool = ConversionLicense.find(:first, :conditions => ["sam_customer_id = ? and product_id = ?", self.id, conversion_product_map.product.id])
      conversion_adjustment += conversion_license_pool.converted_count if (!conversion_license_pool.nil?)
    end
    conversion_product_map = ConversionProductMap.find(:first, :conditions => ["post_converted_product_id = ?", product])
    if (!conversion_product_map.nil?)
      conversion_license_pool = ConversionLicense.find(:first, :conditions => ["sam_customer_id = ? and product_id = ?", self.id, conversion_product_map.product.id])
      conversion_adjustment += conversion_license_pool.converted_count if (!conversion_license_pool.nil?)
      conversion_adjustment *= -1
    end
    return conversion_adjustment
  end
  
  ######################
  # SEAT COUNT PROFILE #
  ######################

  # Build a profile that contains the seat counts from various sources.  This method assumes that the SAM Customer has already been activated for SC-Licensing
  def build_seat_count_profile(subcommunity_id, time)
    if (subcommunity_id.nil?)
      syncable = true
      license_count_integrity_problems_found = false
      real_license_count_discrepancies_found = false
      scale_array = []
	  @lm_version = (SamCustomerSamcComponent.find_by_sam_customer_and_component_code(self, "LM").nil?) ? 1 : 2
      subcommunities = self.available_subcommunities
      subcommunities.each do |subcommunity|
        subcommunity_id = subcommunity.id
        scale = SubcommunityScale.new(subcommunity)
        scale.entitlement_count = self.entitlement_count(subcommunity_id).to_i
        scale.allocated_pool_count = self.allocated_pool_count(subcommunity_id).to_i
		    scale.unregistered_pool_count = self.unregistered_pool_count(subcommunity_id).to_i
		    scale.net_plcc_count = self.net_plcc_count(subcommunity_id).to_i
		    scale.conversion_factor = self.conversion_adjustment_count(subcommunity)
		    puts "unregistered_pool_count: #{scale.unregistered_pool_count}"
        scale.unallocated_pool_count = self.unallocated_pool_count(subcommunity).to_i
        scale.server_count = self.server_count(subcommunity_id).to_i
        scale.enrollment_count = self.total_enrollment_count(subcommunity_id).to_i
        scale.virtual_entitlement_count = self.virtual_entitlement_count(subcommunity_id, time).to_i if time
        if (scale.license_count_discrepancy?)
          scale.seat_pool_pending_reallocations = SeatPool.find_by_pending_reallocations(self.id, subcommunity_id)  
          real_license_count_discrepancies_found = true if scale.seat_pool_pending_reallocations.nil?
        end
        license_count_integrity_problems_found = true if scale.license_count_integrity_problem?
        syncable = false if (scale.license_count_integrity_problem? || (self.sc_licensing_activated && !scale.ready_for_sync?)) 
        scale_array << scale
      end
      # we can sync only if the SAM customer has been activated for licensing and the license manager is NOT pending activation and
      # there were real license count discrepancies and NO license count integrity problems found
      #resyncable = (!self.sc_licensing_activated.nil?) && (self.licensing_status != SamCustomer.MANAGER_PENDING_ACTIVATION) && 
      #              real_license_count_discrepancies_found && (!license_count_integrity_problems_found)
      
      # we can activate for sc-licensing only if there are no license count integrity problems
      scale_array.sort! {|a,b| a.subcommunity.name <=> b.subcommunity.name}      
      return scale_array, license_count_integrity_problems_found
    else
		  scale.lm_version = (SamCustomerSamcComponent.find_by_sam_customer_and_component_code(self, "LM").nil?) ? 1 : 2
      subcommunity = Subcommunity.find(subcommunity_id)
      scale = SubcommunityScale.new(subcommunity)
      scale.entitlement_count = self.entitlement_count(subcommunity_id).to_i
      scale.allocated_pool_count = self.allocated_pool_count(subcommunity_id).to_i
      scale.unallocated_pool_count = self.unallocated_pool_count(subcommunity).to_i
      scale.server_count = self.server_count(subcommunity_id).to_i
      scale.virtual_entitlement_count = self.virtual_entitlement_count(subcommunity_id, time).to_i if time
      if (scale.license_count_discrepancy?)
        scale.seat_pool_pending_reallocations = SeatPool.find_by_pending_reallocations(self.id, subcommunity_id)
      end
      return scale
    end
  end
  
  
  def unregistered_server
	SamServer.find_by_sam_customer_id_and_server_type(self.id, 2)
  end
  
  
  #####################################################################
  
  def self.count_by_us_state_province
    us_id = Country.find_by_code("US").id
    StateProvince.find(:all, :select => "name, sam_customer_count", :conditions => ["sam_customer_count != 0 and country_id = ?", us_id], :order => "name")
  end
  
  def self.activation_counts_by_state_province
    mailing_address = AddressType.find_by_code(AddressType.MAILING_CODE)
    SamCustomer.find_by_sql(["select sp.id, sp.display_name, count(sc.id) as sam_customer_count, count(auth_activated) as auth_activated_count,
                    count(sc_licensing_activated) as sc_licensing_activated_count, count(update_manager_activated) as update_manager_activated_count from sam_customer sc
                    inner join org on sc.root_org_id = org.id
                    inner join customer c on org.customer_id = c.id
                    inner join customer_address ca on ca.customer_id = c.id
                    inner join state_province sp on ca.state_province_id = sp.id
                    where sc.fake = false and ca.address_type_id = ? and sp.name != '' group by sp.id order by sp.name", mailing_address.id])
  end
  
  def self.retrieve_license_counts_for_schools(sam_customer_id)
      SamCustomer.find_by_sql(["select sssi.id, sssi.name as school_name, c.ucn as school_ucn, ss.name as server_name, p.description as product_name, ssse.allowed_max as allocated_count, 
                                ssse.enrolled as enrolled_count from sam_server_school_enrollments ssse inner join sam_server_school_info sssi on ssse.sam_server_school_info_id = sssi.id
                                inner join sam_server ss on sssi.sam_server_id = ss.id
                                inner join sam_customer sc on ss.sam_customer_id = sc.id
                                inner join subcommunity s on ssse.subcommunity_id = s.id
                                inner join product p on s.product_id = p.id
                                left join org o on sssi.org_id = o.id
                                left join customer c on o.customer_id = c.id
                                where sc.id = ?", sam_customer_id])
  end
  
  
  def validate
    errors.add("Root Organization UCN", " is not valid") if root_org.nil?
  end
  
end

class ComplianceCountSet
  attr_accessor :description, :total_active_count, :total_allocated_count, :max_allowed_on_hosted_servers
  def initialize()
    @description = ""
    @total_active_count = 0
    @total_allocated_count = 0
    @max_allowed_on_hosted_servers = 0
  end
end

class SubcommunityScale

  attr_accessor :subcommunity, :entitlement_count, :allocated_pool_count, :unregistered_pool_count, :unallocated_pool_count, 
				:server_count, :enrollment_count, :virtual_entitlement_count, :seat_pool_pending_reallocations, :net_plcc_count, :conversion_factor
  
  def initialize(subcom)
    @subcommunity = subcom
    @entitlement_count = 0
    @allocated_pool_count = 0
    @unallocated_pool_count = 0
    @server_count = 0
    @virtual_entitlement_count = 0
    @seat_pool_pending_reallocations = nil
	  @unregistered_pool_count = 0
	  @net_plcc_count = 0
	  @conversion_factor = 0
	  @enrollment_count = 0
  end
  
  def license_count_integrity_problem?
    (self.entitlement_count != (self.allocated_pool_count + self.unallocated_pool_count + self.net_plcc_count + self.conversion_factor))
  end
  
  def license_count_discrepancy?
    ((self.server_count + self.unregistered_pool_count	) != self.allocated_pool_count)
  end
  
  def ready_for_sync?
    (self.server_count - self.allocated_pool_count) == self.virtual_entitlement_count
  end
  
  def editable?
    (self.license_count_discrepancy? && self.seat_pool_pending_reallocations.nil?)
  end
  
end

# == Schema Information
#
# Table name: sam_customer
#
#  id                               :integer(10)     not null, primary key
#  root_org_id                      :integer(10)     not null
#  auto_interval                    :integer(10)
#  update_conf                      :boolean
#  install_time                     :string(255)
#  cutover_date                     :datetime
#  active                           :boolean         default(TRUE)
#  registration_date                :datetime
#  fake                             :boolean         default(FALSE)
#  sam_time_zone_id                 :integer(10)
#  sc_licensing_activated           :datetime
#  licensing_status                 :string(1)       default("n"), not null
#  name                             :string(255)     default(""), not null
#  created_at                       :datetime
#  source_entitlement_id            :integer(10)
#  source_user_id                   :integer(10)
#  scholastic_index_id              :integer(10)     default(1), not null
#  auth_activated                   :datetime
#  auth_status                      :string(1)       default("n"), not null
#  update_manager_activated         :datetime
#  update_manager_status            :string(1)       default("n"), not null
#  automatic_license_allocation     :boolean         default(FALSE), not null
#  update_as_available              :integer(10)     default(1), not null
#  licensing_certified              :boolean         default(FALSE), not null
#  automatic_entitlement_assignment :boolean         default(TRUE), not null
#  source_mode                      :string(1)
#  license_count_audit_status       :boolean         default(FALSE), not null
#  manual_license_decommission      :boolean         default(FALSE), not null
#  update_quiz_as_available         :boolean         default(TRUE), not null
#  siteid                           :string(255)
#  auto_resolve_lcd                 :boolean         default(TRUE), not null
#

