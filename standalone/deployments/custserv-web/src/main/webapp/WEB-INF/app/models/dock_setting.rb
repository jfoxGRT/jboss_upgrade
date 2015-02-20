class DockSetting < ActiveRecord::Base
  belongs_to :user
  
  CODE_TASKS = 'T'
  CODE_SAM_CUSTOMERS = 'SC'
     
end

# == Schema Information
#
# Table name: dock_settings
#
#  id        :integer(10)     not null, primary key
#  user_id   :integer(10)     not null
#  dock_code :string(3)       not null
#  status    :integer(10)     not null
#

