class SamCentralMessage < ActiveRecord::Base
  
  set_table_name "sam_central_message"
    
end

# == Schema Information
#
# Table name: sam_central_message
#
#  id         :integer(10)     not null, primary key
#  message    :text            not null
#  created_at :datetime        not null
#  priority   :integer(10)     default(1), not null
#

