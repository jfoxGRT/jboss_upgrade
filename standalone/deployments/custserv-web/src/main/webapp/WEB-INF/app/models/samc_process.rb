class SamcProcess < ActiveRecord::Base
  set_table_name "processes"
  has_many :process_messages
  has_many :process_contexts, :foreign_key => "process_id", :class_name => "ProcessContext"
  belongs_to :user
  
  def self.find_counts_by_process_type
    find(:all, :select => "process_type_code, if(completed_at is not null,1,0) as complete, count(id) as the_count", :order => "process_type_code, complete", :group => "process_type_code, complete")
  end
  
  def self.find_by_sam_customer_and_process_type(sam_customer, process_type_code)
    SamcProcess.find(:all, :select => "p.started_at, p.completed_at, ss.id, ss.name, sc3.id as current_sam_customer_id, sc1.id as old_sam_customer_id, sc1.name as old_sam_customer, sc2.id as new_sam_customer_id, sc2.name as new_sam_customer",
                      :joins => "p inner join process_contexts pc on (pc.process_id = p.id and pc.name = 'resource') 
                                inner join process_contexts pc2 on (pc2.process_id = p.id and pc2.name = 'oldSamCustomerId') 
                                inner join process_contexts pc3 on (pc3.process_id = p.id and pc3.name = 'newSamCustomerId') 
                                inner join sam_customer sc1 on (pc2.value = sc1.id) inner join sam_customer sc2 on (pc3.value = sc2.id) 
                                inner join sam_server ss on (pc.value = ss.id) inner join sam_customer sc3 on (ss.sam_customer_id = sc3.id)", 
                      :conditions => ["p.process_type_code = ? and (sc1.id = ? or sc2.id = ?)", process_type_code, sam_customer.id, sam_customer.id])
  end
  
end

# == Schema Information
#
# Table name: processes
#
#  id                :integer(10)     not null, primary key
#  process_type_code :string(8)       not null
#  process_token     :string(255)     not null
#  completed_at      :datetime
#  started_at        :datetime
#  validated_at      :datetime
#  pct_complete      :integer(10)     default(0), not null
#  user_id           :integer(10)
#

