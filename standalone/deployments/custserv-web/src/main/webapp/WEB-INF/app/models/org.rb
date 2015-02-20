class Org < ActiveRecord::Base
  set_table_name "org"
  belongs_to :customer
  belongs_to :public_private
  belongs_to :religious_affiliation
  has_many :sam_servers, :foreign_key => "root_org_id", :class_name => "SamServer"
  has_one :sam_customer, :foreign_key => "root_org_id", :class_name => "SamCustomer"
  has_one :entitlement_assignment_suppression, :foreign_key => "org_id", :class_name => "EntitlementAssignmentSuppression"
  belongs_to :top_level_org, :foreign_key => "top_level_org_id", :class_name => "Org"
  has_many :top_level_org_mappings, :foreign_key => "org_id", :class_name => "TopLevelOrg"
  has_many :top_level_orgs, :through => :top_level_org_mappings
  
  has_many :descendant_orgs, :foreign_key => "top_level_org_id", :class_name => "TopLevelOrg"

  def self.getSelfAndDescendants
    
  end
  
  def parent_org
    parent_relationships = self.customer.parent_relationships
    (parent_relationships.length == 0) ? nil : parent_relationships[0].related_customer.org
  end
  
  def self.find_by_ucn(ucn)
    customer = Customer.find_by_ucn(ucn)
    return nil if customer.nil?
    customer.org    
  end
  
  def self.find_ucn_by_sam_customer_id(id)
    sam_customer = SamCustomer.find_ucn_by_sam_customer_id(id)
    return nil if sam_customer.nil?
    Org.first(:all, :conditions => ["org.id = ?", sam_customer.root_org_id])    
  end
  
  def self.find_summary_details(org_id)
    mailing_address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    main_phone_type = TelephoneType.find_by_code(TelephoneType.MAIN_CODE)
    Org.find(:first, :select => "o.name as org_name, c.ucn, ca.city_name, ca.zip_code, sp.code as state_code, ca.county_code, t.telephone_number",
             :joins => "o inner join customer c on o.customer_id = c.id
                        inner join customer_address ca on ca.customer_id = c.id
                        left join state_province sp on ca.state_province_id = sp.id
                        left join telephone t on t.customer_id = c.id",
             :conditions => ["ca.address_type_id = ? and o.id = ? and (t.customer_id is null or t.telephone_type_id = ?)", mailing_address_type.id, org_id, main_phone_type.id])
  end

  def self.root_organizations
    sql = <<EOS
    SELECT distinct o.*
      FROM org o
        inner join entitlement e on o.id = e.root_org_id
      ORDER BY name asc;
EOS

    Org.find_by_sql(sql)    
  end
  
  def self.find_by_keyword_and_zip_code(keyword, zip_code)
    address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    keyword_search = "'%#{keyword}%'"
    Org.find_by_sql(["select org.id, org.name, ca.address_line_1, ca.address_line_2, c.ucn, ca.city_name, ca.zip_code, sp.name as state_name, cs.description as status_description from org
                      inner join customer c on org.customer_id = c.id
                      inner join customer_address ca on ca.customer_id = c.id
                      inner join customer_status cs on c.customer_status_id = cs.id
                      inner join state_province sp on ca.state_province_id = sp.id
                      where ca.zip_code = ? and org.name like " + keyword_search + " and c.customer_group_id in (9,12) and ca.address_type_id = ?", zip_code, address_type.id])
  end
  
  def self.countTopLevelsByStateProvinceCountryCodes(stateProvinceCode, countryCode)
  
    internalOrg = Customer.find_by_ucn(-1).org
  
    sql = <<EOS
    select count(*) as count from org o
      inner join customer c on o.customer_id = c.id
      inner join top_level_org tlo on o.id = tlo.org_id
      inner join customer_address ca on c.id = ca.customer_id
      inner join state_province sp on ca.state_province_id = sp.id
      inner join country on sp.country_id = country.id
    where sp.code = '#{stateProvinceCode}' and country.code = '#{countryCode}' and tlo.top_level_org_id = #{internalOrg.id}
EOS
    
    results = ActiveRecord::Base.connection.select_one sql
    results['count']
  
  end
  
  def self.getInternalOrg()
    return Customer.find_by_ucn(-1).org
  end
  
  def isTopLevel?()
    return (self.top_level_orgs[0] == Org.getInternalOrg)
  end
  
  def isDistrict?()
    districtGroup = CustomerGroup.find_by_code("D")
    return (self.customer.customer_group == districtGroup)
  end
  
  
  def self.search(params, limit=-1, sortby="ucn")
    
    org_term_provided = false
    address_term_provided = false
    city_term_provided = false
    
    conditions_clause_str = "ca.address_type_id = " + AddressType.find_by_code(AddressType.MAILING_CODE).id.to_s
    conditions_clause_fillins = []
    joins_clause_str = "o inner join customer c on o.customer_id = c.id inner join customer_group cg on c.customer_group_id = cg.id
                        inner join customer_type ct on c.customer_type_id = ct.id inner join customer_status cs on c.customer_status_id = cs.id
                        inner join customer_address ca on ca.customer_id = c.id inner join state_province sp on ca.state_province_id = sp.id
                        left join sam_customer sc on sc.root_org_id = o.id"
    select_clause_str = "o.id, c.ucn, o.name as org_name, o.number_of_children, ca.address_line_1, ca.city_name, sp.name as state_name, ca.postal_code, cg.description as group_description,
                         ct.description as type_description, cs.description as status_description, sc.id as sam_customer_id"
    if (params[:customer_group_id] and params[:customer_group_id] == "D")
      conditions_clause_str += " and cg.id = ?"
      conditions_clause_fillins << CustomerGroup.find_by_code(CustomerGroup.DISTRICT_CODE).id
    elsif (params[:customer_group_id] and params[:customer_group_id] == "S")
      conditions_clause_str += " and cg.id in (?, ?)"
      school_groups = CustomerGroup.find(:all, :conditions => ["code in (?, ?)", CustomerGroup.SCHOOL_CODE, CustomerGroup.OTHER_SCHOOLS_CODE])
      school_groups.each {|sc| conditions_clause_fillins << sc.id}
    end
    if (params[:customer_type_id] and !params[:customer_type_id].empty?)
      conditions_clause_str += " and ct.id = ?"
      conditions_clause_fillins << params[:customer_type_id]
    end
    if (params[:zip_code] and !params[:zip_code].empty?)
      conditions_clause_str += " and ca.zip_code = ?"
      conditions_clause_fillins << params[:zip_code].to_i
    end
    if (params[:state_id] and !params[:state_id].empty?)
      conditions_clause_str += " and sp.id = ?"
      conditions_clause_fillins << params[:state_id]
    end
    if (params[:position] and params[:position] == "TLO")
      conditions_clause_str += " and top_level_org.top_level_org_id = " + Org.getInternalOrg.id.to_s
      joins_clause_str += " inner join top_level_org on o.id = top_level_org.org_id"
    end
    if (params[:ucn] and !params[:ucn].empty?)
      conditions_clause_str += " and c.ucn = ?"
      conditions_clause_fillins << params[:ucn]
    end
    if (params[:status] and !params[:status].empty?)
      conditions_clause_str += " and cs.description = ?"
      conditions_clause_fillins << params[:status] 
    end
    if (params[:name] and !params[:name].empty?)
      keyword_search = "'%%#{params[:name]}%%'"
      conditions_clause_str += (" and o.name like " + keyword_search)
      org_term_provided = true
    end
    if (params[:address] and !params[:address].empty?)
      keyword_search = "'%#{params[:name]}%'"
      conditions_clause_str += (" and ca.address_line_1 like " + keyword_search)
      address_term_provided = true
    end
    if (params[:city] and !params[:city].empty?)
      keyword_search = "'%#{params[:city]}%'"
      conditions_clause_str += (" and ca.city_name like " + keyword_search)
      city_term_provided = true
    end
     
    #if (params[:address] && !params[:address].empty? && params[:state_id].empty?)
     # return []
   # end
    logger.info("SELECT clause: #{select_clause_str}")
    logger.info("JOINS clause: #{joins_clause_str}")
    logger.info("WHERE clause: #{conditions_clause_str}")
    logger.info("LIMIT: #{limit}")
    
    if(limit > 0)
      Org.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                     :conditions => [conditions_clause_str, conditions_clause_fillins].flatten,
                     :order => sortby,
                     :limit => limit)
    else #negative value of limit indicates no limit
      Org.find(:all, :select => select_clause_str, 
                     :joins => joins_clause_str,
                     :conditions => [conditions_clause_str, conditions_clause_fillins].flatten,
                     :order => sortby)
     end
  end
 
end

# == Schema Information
#
# Table name: org
#
#  id                       :integer(10)     not null, primary key
#  customer_id              :integer(10)     not null
#  name                     :string(100)     not null
#  alt_name                 :string(30)
#  url                      :string(200)
#  public_private_id        :integer(10)
#  religious_affiliation_id :integer(10)
#  top_level_org_id         :integer(10)
#  number_of_children       :integer(10)
#

