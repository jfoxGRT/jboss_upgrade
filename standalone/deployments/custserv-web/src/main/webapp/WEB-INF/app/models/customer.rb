class Customer < ActiveRecord::Base
  set_table_name "customer"
  belongs_to :customer_type
  belongs_to :customer_group
  belongs_to :customer_status
  belongs_to :customer_realm
  has_many :customer_addresses, :foreign_key => "customer_id", :class_name => "CustomerAddress"
  has_many :parent_relationships, :foreign_key => "customer_id", :class_name => "CustomerRelationship"
  has_many :child_relationships, :foreign_key => "related_customer_id", :class_name => "CustomerRelationship"
  has_many :customer_roles
  has_many :telephones
  has_one :org

  def state
    self.customer_addresses[0].state_province
  end
  
  def closed?
    return (self.customer_status.code == CustomerStatus.CLOSED_CODE) ? true : false
  end
  
  def mailing_address
    CustomerAddress.find(:first, :conditions => ["customer_id = ? and address_type_id = 5", self.id])
  end
  
  def main_phone
    Telephone.find(:first, :conditions => ["customer_id = ? and telephone_type_id = 5", self.id])
  end
  
  
  def self.find_details_by_ucn_list(ucn_list)
    ucn_str = "("
    last = ucn_list.length - 1
    for i in 0...ucn_list.length
      ucn_str += ucn_list[i]
      ucn_str += "," if i != last
    end
    ucn_str += ")"
    puts "ucn_str: " + ucn_str
    Customer.find(:select => "o.name, c.id, c.ucn, o.id as org_id, o.number_of_children, ca.address_line_1, ca.address_line_2, ca.address_line_3,
                                      ca.address_line_4, ca.address_line_5, ca.city_name, sp.name as state_name,
                                      ca.postal_code, ca.county_code, co.name as country_name, sc.name as sam_customer_name, sc.id as sam_customer_id, 
                                      t.telephone_number, cg.description as group_description, ct.description as type_description,
                                      cs.description as status_description, c.customer_added_date, sc.id as sam_customer_id, sc.registration_date, sc.sc_licensing_activated",
                          :joins => "c inner join org o on o.customer_id = c.id 
                                     inner join customer_address ca on ca.customer_id = c.id
                                     inner join state_province sp on ca.state_province_id = sp.id
                                     inner join country co on ca.country_id = co.id
                                     left join sam_customer sc on sc.root_org_id = o.id
                                     left join telephone t on t.customer_id = c.id
                                     inner join customer_group cg on c.customer_group_id = cg.id
                                     inner join customer_type ct on c.customer_type_id = ct.id
                                     inner join customer_status cs on c.customer_status_id = cs.id",
                          :conditions => ["ca.address_type_id = 5 and (t.telephone_type_id is null or t.telephone_type_id = 5) and c.ucn in #{ucn_str}"])
  end
  
  def find_by_ucn (ucn)
    ucn = Customer.where("ucn = ?", ucn)
  end
  
  def self.find_ucn_by_sam_customer_id(id)
    org = Org.find_ucn_by_sam_customer_id(id)
    return nil if org.nil?
    Customer.first(:all, :conditions => ["id = ?", org.customer_id])
  end
  
  def self.find_details_by_ucn(ucn)
    Customer.find(:first, :select => "o.name, c.id, c.ucn, o.id as org_id, o.number_of_children, ca.address_line_1, ca.address_line_2, ca.address_line_3,
                                      ca.address_line_4, ca.address_line_5, ca.city_name, sp.name as state_name, tlo.top_level_org_id, 
                                      ca.postal_code, ca.county_code, co.name as country_name, o.number_of_children, sc.name as sam_customer_name, 
                                      sc.id as sam_customer_id, t.telephone_number, cg.description as group_description, ct.description as type_description, 
                                      cs.description as status_description, c.customer_added_date, sc.id as sam_customer_id, sc.registration_date, 
                                      sc.sc_licensing_activated, tlo.top_level_org_id, sc1.name as installed_at_sam_customer, sc1.id as installed_at_sam_customer_id, 
                                      cr.related_customer_id as parent",
                          :joins => "c inner join org o on o.customer_id = c.id 
                                     inner join customer_address ca on ca.customer_id = c.id
                                     left join state_province sp on ca.state_province_id = sp.id
                                     inner join country co on ca.country_id = co.id
                                     left join sam_customer sc on sc.root_org_id = o.id
                                     left join telephone t on t.customer_id = c.id
                                     inner join customer_group cg on c.customer_group_id = cg.id
                                     inner join customer_type ct on c.customer_type_id = ct.id
                                     inner join customer_status cs on c.customer_status_id = cs.id
                                     left join top_level_org tlo on tlo.org_id = o.id
									 left join sam_server_school_info sssi on sssi.org_id = o.id
									 left join sam_server ss on ss.id = sssi.sam_server_id
									 left join sam_customer sc1 on sc1.id = ss.sam_customer_id
                   left join customer_relationship cr on cr.customer_id=c.id",
                          :conditions => ["ca.address_type_id = 5 and (t.telephone_type_id is null or t.telephone_type_id = 5) and c.ucn = ?", ucn])
  end
  
  def self.find_parent_by_customer_id(customer_id)
    Customer.find(:first, :select => "c.*", :joins => "c inner join customer_relationship cr on cr.related_customer_id = c.id",
                  :conditions => ["cr.customer_id = ?", customer_id])
  end
  
  
  def self.find_descendants_minimum_field_set(ucn)
    Customer.find_by_sql(["select o.name, o.number_of_children, c.id, c.ucn, cr.created_at, cg.description as group_description, sc.active as sam_customer_active from
                           customer c inner join customer_relationship cr on cr.customer_id = c.id
                           inner join org o on o.customer_id = cr.customer_id
                           inner join customer_group cg on c.customer_group_id = cg.id
                           left join sam_customer sc on sc.root_org_id = o.id
                           where cr.related_customer_id in (select id from customer where ucn = ?) order by o.name", ucn])
  end
  
  
  def self.getByStateProvinceCountryCodes(stateProvinceCode, countryCode)
    sql = <<EOS
    select distinct c.* from customer c
      inner join customer_address ca on c.id = ca.customer_id
      inner join customer_group cg on c.customer_group_id = cg.id
      inner join state_province sp on ca.state_province_id = sp.id
      inner join country on sp.country_id = country.id
    where sp.code = '#{stateProvinceCode}' and country.code = '#{countryCode}' and cg.code != 'IND'
EOS
    Customer.find_by_sql(sql)
  end

   
end

# == Schema Information
#
# Table name: customer
#
#  id                  :integer(10)     not null, primary key
#  ucn                 :integer(10)     not null
#  customer_group_id   :integer(10)     not null
#  customer_type_id    :integer(10)     not null
#  customer_status_id  :integer(10)     default(1), not null
#  customer_added_date :date
#  id_merge_to         :integer(10)
#

