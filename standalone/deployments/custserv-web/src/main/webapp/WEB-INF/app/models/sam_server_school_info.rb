class SamServerSchoolInfo < ActiveRecord::Base
  set_table_name "sam_server_school_info"
  belongs_to :sam_server, :class_name => "SamServer", :foreign_key => "sam_server_id"
  belongs_to :org, :class_name => "Org", :foreign_key => "org_id"
  has_many :sam_server_school_enrollments
  has_many :sam_server_class_infos
  
  @@STATUS_NOT_RESOLVED = 'n'
  @@STATUS_TRANSITION = 't'
  @@STATUS_PENDING_CSI_VERIFICATION = 'p'
  @@STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE = 'y'
  @@STATUS_PUBLISHED = 'z'
  @@STATUS_RESOLVED = 'r'
  
  def self.STATUS_NOT_RESOLVED
  	@@STATUS_NOT_RESOLVED
  end
  
  def self.STATUS_TRANSITION
  	@@STATUS_TRANSITION
  end
  
  def self.STATUS_PENDING_CSI_VERIFICATION
  	@@STATUS_PENDING_CSI_VERIFICATION
 end
 
 def self.STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE
  	@@STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE
 end
 
 def self.STATUS_PUBLISHED
   @@STATUS_PUBLISHED
 end
  
  def self.STATUS_RESOLVED
  	@@STATUS_RESOLVED
 end
 
 def self.STATUS_REJECTED
    @@STATUS_REJECTED
  end

  def school_enrollment_by_subcommunity(subcom)
    school_enrollments = self.sam_server_school_enrollments
    return nil if school_enrollments.empty?
    self.sam_server_school_enrollments.detect{|ssse| ssse.subcommunity == subcom}
  end
  
  def self.find_by_sam_customer(sam_customer)
    SamServerSchoolInfo.find_by_sql(["select * from sam_server_school_info sssi
                inner join sam_server ss on sssi.sam_server_id = ss.id
                inner join sam_customer sc on ss.sam_customer_id = sc.id
                where ss.status = 'a' and sc.id = ?", sam_customer.id])
  end
  
     def self.find_unmatched_schools(sam_customer)
      SamServerSchoolInfo.find(:all, :select => "sssi.id as sssi_id, sssi.name as school_name, sssi.address1, sssi.city, sssi.state, sssi.postal_code, sssi.phone, ss.name as server_name", 
                :joins => "sssi inner join sam_server ss on sssi.sam_server_id = ss.id", 
                :conditions => ["ss.sam_customer_id = ? and ss.status = 'a' and sssi.org_id is null and (sssi.status = ? or sssi.status = ?)", sam_customer.id, SamServerSchoolInfo.STATUS_NOT_RESOLVED, SamServerSchoolInfo.STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE],
                :order => "school_name asc, server_name asc")
     end
  
  
  def get_display_status
    display_string = String.new
    
    display_string = 'Unresolved' if self.status = @@STATUS_NOT_RESOLVED
    display_string = 'In Transition' if self.status = @@STATUS_TRANSITION
    display_string = 'Pending CSI Verification After Submission' if self.status = @@STATUS_PENDING_CSI_VERIFICATION
    display_string = 'Published' if self.status = @@STATUS_PUBLISHED
    
    return display_string
  end
  
  def get_class_count
    SamServerClassInfo.count(:conditions => "sam_server_school_info_id = #{self.id}")
  end
  
end

# == Schema Information
#
# Table name: sam_server_school_info
#
#  id             :integer(10)     not null, primary key
#  sam_server_id  :integer(10)     not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  sam_school_id  :string(255)     not null
#  name           :string(255)     not null
#  student_count  :string(255)
#  school_number  :string(255)
#  title          :string(255)
#  first_name     :string(255)
#  middle_name    :string(255)
#  last_name      :string(255)
#  address1       :string(255)
#  address2       :string(255)
#  address3       :string(255)
#  city           :string(255)
#  state          :string(255)
#  country        :string(255)
#  postal_code    :string(255)
#  phone          :string(255)
#  email          :string(255)
#  org_id         :integer(10)
#  match_selected :boolean         default(FALSE), not null
#  status         :string(1)       default("n"), not null
#  fake           :boolean         default(FALSE), not null
#

