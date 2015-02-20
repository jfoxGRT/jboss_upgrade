class SamServerClassInfo < ActiveRecord::Base
  set_table_name "sam_server_class_info"
  belongs_to :sam_server_school_info
  attr_accessor :communities_string #make public
  
  # Display all managed products for each class in school view
  # Example: "FM, SMI, XT, RTNG, R180NG, R180, SRI, SPI, RA, SRC, S44, FAD, RT"
  def find_communities
  	products = ""
  	
  	products_array = SamServerClassInfo.find(:all, :select => "c.code",
  								  :joins => "ssci inner join sam_server_class_info_communities sscic on sscic.sam_server_class_info_id = ssci.id 
											 inner join community c on sscic.community_id = c.id ",
	  							  :conditions => ["ssci.id = ?", self.id])
	
	# Allows a blank cell to display if no managed products are present
	
	if (!(products_array.nil?) && products_array.size > 0) then
		arraysize = products_array.size-1
		
		for i in 0...arraysize
			products += products_array[i].code + ", "
		end
		
		products += products_array[arraysize].code
	end
	
	return products
	
  end
  
end

# == Schema Information
#
# Table name: sam_server_class_info
#
#  id                        :integer(10)     not null, primary key
#  created_at                :datetime        not null
#  updated_at                :datetime        not null
#  sam_class_id              :string(255)     not null
#  name                      :string(255)     not null
#  sam_server_school_info_id :integer(10)     not null
#

