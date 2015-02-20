require 'java'
import 'java.util.HashMap'
import 'java.lang.Character'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
class Entitlement < ActiveRecord::Base
  set_table_name "entitlement"
  belongs_to :license_duration
  belongs_to :license_portability
  belongs_to :license_lifetime
  belongs_to :item
  belongs_to :intl_order_line
  belongs_to :order_type
  belongs_to :product
  belongs_to :sc_entitlement_type
  belongs_to :sam_customer, :foreign_key => "sam_customer_id", :class_name => "SamCustomer"
  has_many :entitlement_orgs
  has_one :entitlement_audit
  has_many :sam_servers, :foreign_key => "registration_entitlement_id", :class_name => "SamServer"
  has_many :alert_instances, :foreign_key => "entitlement_id", :class_name => "AlertInstance"
  has_many :entitlement_grace_periods, :foreign_key => "entitlement_id", :class_name => "EntitlementGracePeriod"
  has_many :virtual_entitlement_audits, :foreign_key => "entitlement_id", :class_name => "VirtualEntitlementAudit"
  belongs_to :bill_to_org, :foreign_key => "bill_to_org_id", :class_name => "Org"
  belongs_to :ship_to_org, :foreign_key => "ship_to_org_id", :class_name => "Org"
  belongs_to :install_to_org, :foreign_key => "install_to_org_id", :class_name => "Org"
  belongs_to :renewal_entitlement, :foreign_key => "renewal_entitlement_id", :class_name => "Entitlement"
  
  MARKETING_VERSIONS = [["1.0", "1.0"], ["1.1", "1.1"], ["1.2", "1.2"], ["1.3", "1.3"], ["1.4", "1.4"], ["1.5", "1.5"], 
                      ["1.6", "1.6"], ["1.7", "1.7"], ["2.0", "2.0"]]
            
  def self.index_by_status(sam_customer, sam_server_product, status)
    where_fragment = (sam_server_product.nil?) ? "" : (sam_server_product == true ? "(p.sam_server_product = true or (p.sam_server_product = false and cpm.product_id is not null)) and " : "p.sam_server_product = false and cpm.product_id is null and ")
    case status
        when "Pending" then Entitlement.find(:all, :select => "p.id, p.description, count(e.id) as result_count", :joins => "e inner join product p on e.product_id = p.id left join conversion_product_maps cpm on p.id = cpm.product_id", 
                          :conditions => ["#{where_fragment} e.sam_customer_id = ? and (date(e.subscription_start) > curdate()) and e.seats_active = false", sam_customer.id],
                          :group => "p.id")
        when "Active" then Entitlement.find(:all, :select => "distinct p.id, p.description, count(e.id) as result_count", :joins => "e inner join product p on e.product_id = p.id left join conversion_product_maps cpm on p.id = cpm.product_id", 
                          :conditions => ["#{where_fragment} e.sam_customer_id = ? and ((p.sam_server_product = false and (e.subscription_start is null or e.seats_active = true or (date(e.subscription_start) <= curdate() and date(e.subscription_end) >= curdate()) )) or (p.sam_server_product = true and ((date(e.subscription_start) <= curdate() and date(e.subscription_end) >= curdate()) or e.seats_active = true)))", sam_customer.id],
                          :group => "p.id")
		when "Grace Period" then Entitlement.find(:all, :select => "p.id, p.description, count(e.id) as result_count", :joins => "e inner join product p on e.product_id = p.id left join conversion_product_maps cpm on p.id = cpm.product_id left join entitlement_grace_periods egp on e.id = egp.entitlement_id",
						  :conditions => ["#{where_fragment} e.sam_customer_id = ? and date(e.subscription_end) < curdate() and (ifnull(date(egp.end_date), date(e.subscription_end)) >= curdate())", sam_customer.id],
						  :group => "p.id")
        when "Expired" then Entitlement.find(:all, :select => "p.id, p.description, count(e.id) as result_count", :joins => "e inner join product p on e.product_id = p.id left join conversion_product_maps cpm on p.id = cpm.product_id left join entitlement_grace_periods egp on e.id = egp.entitlement_id", 
                          :conditions => ["#{where_fragment} e.sam_customer_id = ? and ifnull(date(egp.end_date), date(e.subscription_end)) < curdate() and e.seats_active = false", sam_customer.id],
                          :group => "p.id")
        else Entitlement.find(:all, :select => "p.id, p.description, count(e.id) as result_count", :joins => "e inner join product p on e.product_id = p.id left join conversion_product_maps cpm on p.id = cpm.product_id", 
                          :conditions => ["#{where_fragment} e.sam_customer_id = ?", sam_customer.id],
                          :group => "p.id")
    end
  end
  
  
  def self.service_plans_near_expiration(sam_customer)
    entitlements = Entitlement.find(:all, :select => "e.id, datediff(e.subscription_end, curdate()) as days_to_expiration", :joins => "e inner join product p on e.product_id = p.id",
            :conditions => ["sam_customer_id = ? and p.product_group_id in (12,13,14,16,20) and datediff(e.subscription_end, curdate()) <= 60", sam_customer.id])
    entitlement.each do |e|
      
    end
  end
  
  
  
  def self.index_by_license_type(sam_customer)
    Entitlement.find_by_sql(["select p.id as product_id, p.description as product_description, scet.code as license_type_code, sum(e.license_count)
                  as result_count from entitlement e inner join sc_entitlement_type scet on e.sc_entitlement_type_id = scet.id
                  inner join product p on e.product_id = p.id where e.sam_customer_id = ? and e.seats_active = true group by p.id,
                  scet.id order by p.description, scet.code",sam_customer.id])
  end
  
  
  def self.total_virtual_license_count(sam_customer, subcommunity)
    product = subcommunity.product
    virtual_type = ScEntitlementType.virtual
    Entitlement.sum("license_count", :conditions => ["sam_customer_id = ? and product_id = ? and sc_entitlement_type_id = ?", sam_customer.id, product.id, virtual_type.id])
  end


  def self.search(params, limit=-1, sortby="e.id")
    conditions_clause_str = ""
    conditions_clause_fillins = []
    joins_clause_str = "e inner join product p on e.product_id = p.id left join sam_customer sc on e.sam_customer_id = sc.id"
    joins_clause_str += " left join org on sc.root_org_id = org.id 
                        left join customer c on org.customer_id = c.id 
                        left join customer_address ca on ca.customer_id = c.id 
                        left join state_province sp on ca.state_province_id = sp.id"
    select_clause_str = "distinct e.id, e.tms_entitlementid, e.sam_customer_id, e.created_at, e.ordered, e.license_count, 
                         e.subscription_start, e.subscription_end, e.order_num, e.invoice_num, p.description as 
                         product_description, sc.name as sam_customer_name, sp.name as state_name"
    
    if (!params[:tms_entitlementid].empty?)
      # if the TMS entitlement ID was specified, then there's no reason to search on any other parameters
      keyword_search = "'%%#{params[:tms_entitlementid]}%%'"
      conditions_clause_str += "e.tms_entitlementid like " + keyword_search
      #conditions_clause_fillins << params[:tms_entitlementid]
    elsif (params[:id] && !params[:id].empty?)
      conditions_clause_str += "e.id = ?"
      conditions_clause_fillins << params[:id]
    elsif (!params[:order_num].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += "e.order_num = ?"
      conditions_clause_fillins << params[:order_num] 
    else
      if (params[:unassigned] == "1")
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.sam_customer_id is null"
      end
      if (!params[:product_group_id].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "p.product_group_id = ?"
        conditions_clause_fillins << params[:product_group_id]
        joins_clause_str += " inner join product_group pg on p.product_group_id = pg.id"
        select_clause_str += ", pg.description as product_group_description"
      end
      if (!params[:product_id].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.product_id = ?"
        conditions_clause_fillins << params[:product_id]
      end
      if (params[:sc_entitlement_type_id] and !params[:sc_entitlement_type_id].empty?)
        sc_entitlement_type_code = ScEntitlementType.find(params[:sc_entitlement_type_id]).code
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.sc_entitlement_type_id = ?"
        conditions_clause_fillins << params[:sc_entitlement_type_id]
      end
      if (!params[:entitlement_type_id].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.order_type_id = ?"
        conditions_clause_fillins << params[:entitlement_type_id]
        joins_clause_str += " inner join order_type ot on e.order_type_id = ot.id"
        select_clause_str += ", ot.description"
      end
      if (!params[:license_count].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.license_count = ?"
        conditions_clause_fillins << params[:license_count].to_i
      end
      if (!params[:invoice_num].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.invoice_num = ?"
        conditions_clause_fillins << params[:invoice_num]
      end
      if (params[:sam_customer_id] and !params[:sam_customer_id].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.sam_customer_id = ?"
        conditions_clause_fillins << params[:sam_customer_id].to_i
      end
    
      if (params[:bill_to_ucn] and !params[:bill_to_ucn].empty?)
        bill_to_org = Org.find(:first, :select => "org.*", :joins => "inner join entitlement_org eo on eo.org_id = org.id 
                                                             inner join customer c on org.customer_id = c.id",
                                                            :conditions => ["c.ucn = ?", params[:bill_to_ucn]])
        return [] if bill_to_org.nil?
        #joins_clause_str += " inner join entitlement_org eo on eo.org_id = org.id"
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.bill_to_org_id = ?"
        conditions_clause_fillins << bill_to_org.id
      end
      if (params[:ship_to_ucn] and !params[:ship_to_ucn].empty?)
        ship_to_org = Org.find(:first, :select => "org.*", :joins => "inner join entitlement_org eo on eo.org_id = org.id 
                                                             inner join customer c on org.customer_id = c.id",
                                                           :conditions => ["c.ucn = ?", params[:ship_to_ucn]])
        return [] if ship_to_org.nil?
        #joins_clause_str += " inner join entitlement_org eo on eo.org_id = org.id"
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += "e.ship_to_org_id = ?"
        conditions_clause_fillins << ship_to_org.id
      end
      if (!params[:state_id].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        #joins_clause_str += " inner join org on sc.root_org_id = org.id inner join customer c on org.customer_id = c.id inner join customer_address ca on ca.customer_id = c.id inner join state_province sp on ca.state_province_id = sp.id"
        conditions_clause_str += "ca.state_province_id = ?"
        conditions_clause_fillins << params[:state_id]
        #select_clause_str += ", sp.name as state_name"
      end
      if (!params[:order_start_date].empty? and !params[:order_end_date].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += " e.ordered between '#{params[:order_start_date]} #{params[:order_start_time]}' and '#{params[:order_end_date]} #{params[:order_end_time]}'"
      elsif (!params[:order_start_date].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += " e.ordered >= '#{params[:order_start_date]} #{params[:order_start_time]}'"
      elsif (!params[:order_end_date].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += " e.ordered <= '#{params[:order_end_date]} #{params[:order_end_time]}'"
      end
      if (!params[:created_at_start_date].empty? and !params[:created_at_end_date].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += " e.created_at between '#{params[:created_at_start_date]} #{params[:created_at_start_time]}' and '#{params[:created_at_end_date]} #{params[:created_at_end_time]}'"
      elsif (!params[:created_at_start_date].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += " e.created_at >= '#{params[:created_at_start_date]} #{params[:created_at_start_time]}'"
      elsif (!params[:created_at_end_date].empty?)
        conditions_clause_str += " and " if !conditions_clause_str.empty?
        conditions_clause_str += " e.created_at <= '#{params[:created_at_end_date]} #{params[:created_at_end_time]}'"
      end
    end
    if (params[:active] == '1')
      # if subscription dates exist, then current time must be between them. else, this condition is meaningless
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += " (e.subscription_start IS null OR e.subscription_end IS null OR now() BETWEEN e.subscription_start AND e.subscription_end)"
    end
    
    if(limit > 0)
      return Entitlement.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                      :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :order => sortby, :limit => limit)
    else #negative value of limit indicates no limit
      return Entitlement.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                      :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :order => sortby)
    end
  end
  
  
  def self.search_for_csv(sam_customer_id, sam_server_product) #separate from search() to keep query logic simpler and avoid null params that will...
                                       #...not be present when just searching by customer id
    select_clause_str = "distinct e.*, p.description as product_description, p.sam_server_product as isSamServerProduct, pg.description as product_group_description, o1.name as bill_to_org_name, o2.name as ship_to_org_name, o3.name as install_to_org_name, c1.ucn as bill_to_ucn, c2.ucn as ship_to_ucn, c3.ucn as install_to_ucn, egp.end_date as grace_period_end_date, gp.description as grace_period_description"
    joins_clause_str = "e INNER JOIN product p ON e.product_id = p.id 
                          INNER JOIN product_group pg ON p.product_group_id = pg.id 
                          left join conversion_product_maps cpm on p.id = cpm.product_id
                          LEFT JOIN org o1 ON e.bill_to_org_id = o1.id 
                          LEFT JOIN org o2 ON e.ship_to_org_id = o2.id 
                          LEFT JOIN org o3 ON e.install_to_org_id = o3.id 
                          LEFT JOIN customer c1 ON o1.customer_id = c1.id 
                          LEFT JOIN customer c2 ON o2.customer_id = c2.id 
                          LEFT JOIN customer c3 ON o3.customer_id = c3.id 
                          LEFT JOIN entitlement_grace_periods egp ON e.id = egp.entitlement_id 
                          LEFT JOIN grace_period gp ON egp.grace_period_id = gp.id"    
    where_fragment = (sam_server_product.nil?) ? "" : (sam_server_product == true ? "(p.sam_server_product = true or (p.sam_server_product = false and cpm.product_id is not null)) and " : "p.sam_server_product = false and cpm.product_id is null and ")
        
    #negative value of limit indicates no limit.  CSV will return all records
    Entitlement.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                     :conditions => ["#{where_fragment} e.sam_customer_id = ?", sam_customer_id], :order => "id")
  end
  

  def self.find_by_product_sam_customer( product, samCustomer ) 
    sql = <<EOS
  select e.* from entitlement e
    inner join product p on e.product_id = p.id
    inner join sam_customer sc on e.sam_customer_id = sc.id
  where 
    p.id = #{product.id} and 
    sc.id = #{samCustomer.id} 
EOS
    Entitlement.find_by_sql(sql)
  end
  
  def isLegacy?
    return false if self.sc_entitlement_type.nil?
    (self.sc_entitlement_type.code == "LEG")
  end
  
  # check if this entitlement is virtual by comparing sc_entitlement_type against both the old and new virtual
  # entitlement types.
  def isVirtual?
    return false if self.sc_entitlement_type.nil?
    (self.sc_entitlement_type.code == "VIRT" or self.sc_entitlement_type.code == "SAM")
  end
  
  def shipped_to_org
    #puts self.entitlement_orgs.length.to_s
    (self.entitlement_orgs.length == 0) ? nil : (self.entitlement_orgs.detect{|eo| eo.entitlement_org_type.code == "S"}).org
  end
  
  def billed_to_org
    (self.entitlement_orgs.length == 0) ? nil : (self.entitlement_orgs.detect{|eo| eo.entitlement_org_type.code == "B"}).org
  end
  
  def shipped_to_entitlement_org
    #puts self.entitlement_orgs.length.to_s
    (self.entitlement_orgs.length == 0) ? nil : (self.entitlement_orgs.detect{|eo| eo.entitlement_org_type.code == "S"})
  end
  
  def billed_to_entitlement_org
    (self.entitlement_orgs.length == 0) ? nil : (self.entitlement_orgs.detect{|eo| eo.entitlement_org_type.code == "B"})
  end
  
  def self.total_licenses(sc, prod)
    Entitlement.sum(:license_count, :conditions => ["sam_customer_id = ? and product_id = ?", sc.id, prod.id])
  end
  
  def self.create_virtual_entitlement(sc, subcom, license_count)
  
    entitlement_info = {}
    entitlement_info[:license_count] = license_count
    entitlement_info[:ordered] = Date.today
    entitlement_info[:license_duration] = LicenseDuration.perpetual
    entitlement_info[:order_num] = "VIRT"
    entitlement_info[:invoice_num] = "VIRT"
    entitlement_info[:item] = Item.find(1)
    entitlement_info[:tms_entitlementid] = "VIRT"
    entitlement_info[:sc_entitlement_type] = ScEntitlementType.virtual
    entitlement_info[:sam_customer] = sc
    entitlement_info[:product] = subcom.product
  entitlement_info[:seats_active] = true
  
    new_entitlement = Entitlement.create(entitlement_info)
    new_entitlement.order_num += new_entitlement.id.to_s
    new_entitlement.invoice_num += new_entitlement.id.to_s
    new_entitlement.tms_entitlementid += new_entitlement.id.to_s
    new_entitlement.save
  
  # broadcast the virtual entitlement message
  message_sender = SC.getBean("messageSender")
  message_sender.sendNewEntitlementInternalMessage(new_entitlement.id, false)
    
    return new_entitlement
  
 end
 
 def self.index(sam_customer, product_type, product = nil, status = nil)
  where_fragment = ""
  case product_type
    when "Licenses" then where_fragment += "and p.sam_server_product = true "
    when "Services" then where_fragment += "and p.sam_server_product = false "
  end
  case status
    when "Pending" then where_fragment += "and date(subscription_start) > curdate() and seats_active = false"
	when "Active" then where_fragment += "and ((p.sam_server_product = false and (e.subscription_start is null or e.seats_active = true or (date(e.subscription_start) <= curdate() and date(e.subscription_end) >= curdate()))) or (p.sam_server_product = true and ((date(e.subscription_start) <= curdate() and date(e.subscription_end) >= curdate()) or e.seats_active = true)))"
	when "Grace Period" then where_fragment += "and date(subscription_end) < curdate() and (ifnull(date(egp.end_date), date(subscription_end))) >= curdate()"
    when "Expired" then where_fragment += "and ifnull(date(egp.end_date), date(e.subscription_end)) < curdate() and e.seats_active = false"
  end
  if (product)
    sam_server_product = product.sam_server_product
    find(:all, :select => "e.*, p.description as product_description, c_it.ucn as install_to_ucn, o_it.id as install_to_org_id, o_it.name as install_to_org_name,
          scet.description as sc_entitlement_type_description",
      :joins => "e inner join product p on e.product_id = p.id
         left join sc_entitlement_type scet on e.sc_entitlement_type_id = scet.id
         left join org o_it on e.install_to_org_id = o_it.id
         left join customer c_it on o_it.customer_id = c_it.id
		 left join entitlement_grace_periods egp on e.id = egp.entitlement_id",
      :conditions => ["e.sam_customer_id = ? and p.id = ? #{where_fragment}", sam_customer.id, product.id], :order => "e.id desc")
  else
    find(:all, :select => "e.*, p.description as product_description, c_it.ucn as install_to_ucn, o_it.id as install_to_org_id, o_it.name as install_to_org_name,
            scet.description as sc_entitlement_type_description",
        :joins => "e inner join product p on e.product_id = p.id
           left join sc_entitlement_type scet on e.sc_entitlement_type_id = scet.id
           left join org o_it on e.install_to_org_id = o_it.id
           left join customer c_it on o_it.customer_id = c_it.id",
        :conditions => ["e.sam_customer_id = ? #{where_fragment}", sam_customer.id], :order => "e.id desc", :limit => "300")
  end
 end

  def self.get_counts_for_open_tasks
    Entitlement.find_by_sql(["select e.order_num, e.invoice_num, count(distinct e.id) as entitlement_count from tasks t 
                              inner join alert_instance ai on ai.task_id = t.id 
                              inner join entitlement e on ai.entitlement_id = e.id 
                              where t.status != 'c' and t.task_type_id = ? group by e.order_num, e.invoice_num", TaskType.find_by_code(TaskType.UNASSIGNED_ENTITLEMENT_CODE).id])
  end
  
  def self.find_all_entitlements_by_order_invoice_nums(order_num, invoice_num)
    Entitlement.find(:all, :select => "t.id as task_id, t.status, e.id as entitlement_id, e.tms_entitlementid, e.created_at, p.description, e.license_count, u.first_name, u.last_name",
                     :joins => "e left join alert_instance ai on ai.entitlement_id = e.id
                                left join tasks t on ai.task_id = t.id
                                inner join product p on e.product_id = p.id
                                left join users u on t.current_user_id = u.id", :conditions => ["e.order_num = ? and e.invoice_num = ?", order_num, invoice_num])
  end
  
  # determine if this entitlement is the result of a Fake Order that was generated within SAMC (not from TMS). specifically, return true iff this entitlement:
  #   1) is of the "TMS" sc_entitlement_type. this excludes virtual and legacy entitlement types.
  #       -- AND --
  #   2) has a non-numeric tms_entitlementid. entitlements from TMS always have integral tms_entitlementid values like 42907284. SAMC fake entitlements have 
  #      tms_entitlementid values like O-1BEAE587-FC22-497A-B0E9-C2ACACC47512. we should probably have a flag for this instead.
  def fake?
    ( sc_entitlement_type.post_samc? && (tms_entitlementid.to_i == 0) )
  end
  
end

# == Schema Information
#
# Table name: entitlement
#
#  id                     :integer(10)     not null, primary key
#  po_num                 :string(255)
#  license_count          :integer(10)
#  license_portability_id :integer(10)
#  ordered                :datetime        not null
#  shipped                :datetime
#  email_address          :string(255)
#  first_name             :string(255)
#  last_name              :string(255)
#  entitlement_type_id    :integer(10)
#  updated_at             :datetime        not null
#  created_at             :datetime        not null
#  license_duration_id    :integer(10)
#  order_num              :string(255)     not null
#  originating_order_num  :string(255)
#  shipment_num           :string(255)
#  invoice_num            :string(255)     not null
#  master_order_num       :string(255)
#  license_count_type_id  :integer(10)
#  item_quantity          :integer(10)
#  contact_ucn            :string(255)
#  subscription_start     :datetime
#  subscription_end       :datetime
#  item_id                :integer(10)
#  tms_entitlementid      :string(255)     not null
#  sc_entitlement_type_id :integer(10)
#  marketing_version      :string(255)
#  sam_customer_id        :integer(10)
#  product_id             :integer(10)
#  pending                :boolean         default(FALSE)
#  bill_to_org_id         :integer(10)
#  ship_to_org_id         :integer(10)
#  install_to_org_id      :integer(10)
#  seats_active           :boolean
#  renewal_entitlement_id :integer(10)
#  generated              :boolean         default(FALSE), not null
#  visibility_level       :string(1)       default("a"), not null
#
