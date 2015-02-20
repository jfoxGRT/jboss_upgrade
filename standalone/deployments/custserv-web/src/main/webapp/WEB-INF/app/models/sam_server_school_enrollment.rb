class SamServerSchoolEnrollment < ActiveRecord::Base
  belongs_to :sam_server_school_info, :class_name => "SamServerSchoolInfo", :foreign_key => "sam_server_school_info_id"
  belongs_to :subcommunity, :class_name => "Subcommunity", :foreign_key => "subcommunity_id"
  
  def self.index(sam_server, subcommunity)
    find(:all, :select => "ssse.*, sssi.id as school_info_id, sssi.name, c.ucn", :joins => "ssse inner join sam_server_school_info sssi on ssse.sam_server_school_info_id = sssi.id
                                         inner join sam_server ss on sssi.sam_server_id = ss.id left join org on sssi.org_id = org.id left join customer c on org.customer_id = c.id", 
                              :conditions => ["ss.id = ? and ssse.subcommunity_id = ?", sam_server.id, subcommunity.id], :order => "sssi.name")
  end
  
  
  def self.zero_all_enrollment_counts(sam_server, subcommunity)
    message_sender = SC.getBean("messageSender")
    ssses = index(sam_server, subcommunity)
    ssses.each do |ssse|
      ssse.enrolled = 0
      ssse.save
      message_sender.sendEnrollmentCountFromUi(ssse.id, "RS", 0)
    end
    sssi = SamServerSubcommunityInfo.find_by_sam_server_and_subcommunity(sam_server, subcommunity)
    sssi.used_seats = 0
    sssi.save
  end
  
  
end

# == Schema Information
#
# Table name: sam_server_school_enrollments
#
#  id                        :integer(10)     not null, primary key
#  sam_server_school_info_id :integer(10)     not null
#  subcommunity_id           :integer(10)     not null
#  enrolled                  :integer(10)
#  allowed_max               :integer(10)
#  allowed_max_from_noop     :integer(10)
#  created_at                :datetime
#  updated_at                :datetime
#

