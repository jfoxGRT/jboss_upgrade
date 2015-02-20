class TaskOrg < ActiveRecord::Base
  belongs_to :task
  belongs_to :org
  belongs_to :entitlement_org_type
  belongs_to :user
  
  def self.unique_org_info(task_id)
    TaskOrg.find(:all, :select => "distinct org.*, c.ucn, cs.description as status_desc, cg.description as group_desc, ct.description as type_desc",
                 :joins => "tsko inner join org on tsko.org_id = org.id
                            inner join customer c on org.customer_id = c.id
                            inner join customer_group cg on c.customer_group_id = cg.id
                            inner join customer_type ct on c.customer_type_id = ct.id
                            inner join customer_status cs on c.customer_status_id = cs.id",
                 :conditions => ["task_id = ?", task_id], :order => "org.name")
  end
  
  
  def self.find_task_org_info_for_open_tasks
    task_type = TaskType.find_by_code(TaskType.UNASSIGNED_ENTITLEMENT_CODE)
    address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    TaskOrg.find(:all, :select => "distinct t.id, o.name, ca.city_name, sp.code, ca.zip_code, ca.county_code, c.ucn, cg.description as group_description,
                                   ct.description as type_description, sc.id as sam_customer_id, sc.registration_date, sc.sc_licensing_activated,
                                   eot.description as entitlement_org_type_description", 
    :joins =>  "inner join tasks t on task_orgs.task_id = t.id 
                inner join org o on task_orgs.org_id = o.id
                inner join customer c on o.customer_id = c.id
                inner join customer_address ca on ca.customer_id = c.id
                inner join customer_group cg on c.customer_group_id = cg.id
                inner join customer_type ct on c.customer_type_id = ct.id
                inner join state_province sp on ca.state_province_id = sp.id
                left join entitlement_org_type eot on task_orgs.entitlement_org_type_id = eot.id
                left join sam_customer sc on sc.root_org_id = o.id", :conditions => ["(t.status = 'u' or t.status = 'a') and t.task_type_id = ? and ca.address_type_id = ?", task_type.id, address_type.id],
                :order => "t.id")
  end
  
  def self.find_task_org_info_for_assigned_tasks(user)
    task_type = TaskType.find_by_code(TaskType.UNASSIGNED_ENTITLEMENT_CODE)
    address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    TaskOrg.find(:all, :select => "distinct t.id, o.name, ca.city_name, sp.code, ca.zip_code, ca.county_code, c.ucn, cg.description as group_description,
                                   ct.description as type_description, sc.id as sam_customer_id, sc.registration_date, sc.sc_licensing_activated,
                                   eot.description as entitlement_org_type_description", 
    :joins =>  "inner join tasks t on task_orgs.task_id = t.id 
                inner join org o on task_orgs.org_id = o.id
                inner join customer c on o.customer_id = c.id
                inner join customer_address ca on ca.customer_id = c.id
                inner join customer_group cg on c.customer_group_id = cg.id
                inner join customer_type ct on c.customer_type_id = ct.id
                inner join state_province sp on ca.state_province_id = sp.id
                left join entitlement_org_type eot on task_orgs.entitlement_org_type_id = eot.id
                left join sam_customer sc on sc.root_org_id = o.id", :conditions => ["t.current_user_id = ? and t.task_type_id = ? and ca.address_type_id = ?", user.id, task_type.id, address_type.id],
                :order => "t.id")
  end
  
  
  def self.find_task_org_info(task)
    address_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    TaskOrg.find(:all, :select => "distinct t.id, o.id as org_id, o.name, ca.city_name, sp.code, ca.zip_code, ca.county_code, c.ucn, cg.description as group_description,
                                   ct.description as type_description, sc.id as sam_customer_id, sc.registration_date, sc.sc_licensing_activated,
                                   eot.description as entitlement_org_type_description, u.email, u.last_name, tlo.top_level_org_id, o.number_of_children", 
    :joins =>  "torg inner join tasks t on torg.task_id = t.id 
                inner join org o on torg.org_id = o.id
                inner join customer c on o.customer_id = c.id
                inner join customer_address ca on ca.customer_id = c.id
                inner join customer_group cg on c.customer_group_id = cg.id
                inner join customer_type ct on c.customer_type_id = ct.id
                inner join top_level_org tlo on o.id = tlo.org_id
                left join state_province sp on ca.state_province_id = sp.id
                left join entitlement_org_type eot on torg.entitlement_org_type_id = eot.id
                left join users u on torg.user_id = u.id
                left join sam_customer sc on sc.root_org_id = o.id", :conditions => ["t.id = ? and ca.address_type_id = ?", task.id, address_type.id],
                :order => "o.name")
  end
  
  def self.build_task_orgs_hash(task_orgs_array)
    task_org_hash = {}
    task_orgs_array.each do |torg|
      hash_key = torg.id
      if (task_org_hash[hash_key].nil?)
        task_org_hash[hash_key] = Array.new(1,torg)
      else
        task_org_hash[hash_key] << torg
      end
    end
    return task_org_hash
  end
  
end

# == Schema Information
#
# Table name: task_orgs
#
#  id                      :integer(10)     not null, primary key
#  task_id                 :integer(10)     not null
#  org_id                  :integer(10)     not null
#  org_factor              :string(1)       default("u"), not null
#  entitlement_org_type_id :integer(10)
#  user_id                 :integer(10)
#

