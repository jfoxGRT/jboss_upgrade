class AuthUser < ActiveRecord::Base
  
  def self.inheritance_column
    nil
  end
  
  set_table_name "auth_user"
  belongs_to :sam_customer
  has_many :sam_server_users
  
  def get_display_type
    display_type = self[:type] # 'type' is a reserved word. self.type resolves to the ActiveRecord AuthUser class here.
    
    if display_type == 'Administrator'
      if determine_is_district_admin
        display_type = 'District Administrator'
      else
        display_type = 'School Administrator'
      end
    elsif display_type == 'Tech'
      if determine_is_district_tech
        display_type = 'District Technical Administrator'
      else
        display_type = 'School Technical Administrator'
      end
    end
    
    display_type    
  end
  
  
  def hasSchools?
    self.sam_server_users.each do |ssu| 
      return true if ssu.is_mapped_to_schools?
    end
    false
  end
  
  
  def determine_is_district_admin        
    self[:type] == 'Administrator' && self.has_all_district_types?
  end
  
  def determine_is_district_tech     
    self[:type] == 'Tech' && self.has_all_district_types?
  end

  
  def has_all_district_types?
    self.sam_server_users.each do |ssu| 
      return false if !ssu.is_district_type
    end
    true
  end
  
  
  # return a string listing the Auth User's SAM Server names, deliminited by comma followed by space.
  # this is intended as a helper for various UI components.
  # note that we return nil if there are no servers, not empty string! 
  def get_sam_servers_string
    sam_servers_string = nil
    self.sam_server_users.each do |sam_server_user|
      if sam_servers_string
        sam_servers_string += ", " + sam_server_user.sam_server.name #name is non-nullable in schema
      else
        sam_servers_string = sam_server_user.sam_server.name
      end
    end
    return sam_servers_string
  end
  
end
# == Schema Information
#
# Table name: auth_user
#
#  id              :integer(10)     not null, primary key
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  uuid            :string(255)     not null
#  type            :string(255)
#  username        :string(255)     not null
#  enabled         :boolean         default(TRUE), not null
#  sam_customer_id :integer(10)     default(9), not null
#  active_token_id :integer(10)
#

