class SamServerUser < ActiveRecord::Base
  
  def self.inheritance_column
    nil
  end
  
  set_table_name "sam_server_user"
  belongs_to :auth_user
  belongs_to :sam_server
  
  def getSchoolInfoUserMapping
    resultSet = SamServerSchoolInfo.find(:all, 
                        :select => "sssi.*",
                        :joins => "sssi INNER JOIN sam_server_school_info_user_mapping sssium ON sssi.sam_school_id = sssium.sam_school_id", 
                        :conditions => ["sssium.user_id = ?", self.user_id])
    return resultSet                    
  end
  
  def get_display_type
    display_type = self[:type] # 'type' is a reserved word. self.type resolves to the ActiveRecord SamServerUser class here.
    
    if display_type == 'Administrator'
      if is_mapped_to_schools?
        display_type = 'School Administrator'
      else
        display_type = 'District Administrator'
      end
    elsif display_type == 'Tech'
      if is_mapped_to_schools?
        display_type = 'School Technical Administrator'
      else
        display_type = 'District Technical Administrator'
      end
    end
    
    display_type    
  end
  
  def is_mapped_to_schools?
    #(SamServerSchoolInfo.count(:joins => "sssi INNER JOIN sam_server_school_info_user_mapping sssium ON sssi.sam_school_id = sssium.sam_school_id",
    #                          :conditions => ["sssium.user_id = ?", self.user_id])) > 0;
    
    # this :first (LIMIT 1) approach seems to run faster than the COUNT approach above, both of which are much better than
    # calling getSchoolInfoUserMapping.length in bad cases
    result = SamServerSchoolInfo.find(:first, 
                        :select => "sssi.id",
                        :joins => "sssi INNER JOIN sam_server_school_info_user_mapping sssium ON sssi.sam_school_id = sssium.sam_school_id", 
                        :conditions => ["sssium.user_id = ?", self.user_id])
    !result.nil? #query returns nil or a single object, not an array
  end
  
end
# == Schema Information
#
# Table name: sam_server_user
#
#  id                    :integer(10)     not null, primary key
#  created_at            :datetime        not null
#  updated_at            :datetime        not null
#  sam_server_id         :integer(10)     not null
#  user_id               :string(255)     not null
#  district_user_id      :string(255)
#  type                  :string(255)
#  username              :string(255)     not null
#  password              :string(255)     not null
#  email                 :string(255)
#  first_name            :string(255)     not null
#  last_name             :string(255)     not null
#  auth_user_id          :integer(10)
#  lexile_fully_computed :boolean
#  lexile_level          :integer(10)
#  e21_course_number     :integer(10)
#  is_ng                 :boolean
#  ereads_enabled        :boolean
#  reading_level         :integer(10)
#  enrolled_stages       :string(255)
#  unlocked_topics       :string(255)
#  is_e21                :boolean
#  enabled               :boolean         default(TRUE), not null
#  is_fmng               :boolean
#  fmng_data             :text
#

