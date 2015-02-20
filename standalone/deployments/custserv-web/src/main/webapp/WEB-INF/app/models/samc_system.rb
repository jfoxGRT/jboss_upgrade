class SamcSystem < ActiveRecord::Base
  set_table_name "samc_system"
  
  validates_length_of :current_license_manager_version, :within => 1..32
end

# == Schema Information
#
# Table name: samc_system
#
#  id                       :integer(10)     not null, primary key
#  maintenance_window_start :datetime
#  maintenance_window_end   :datetime
#  lm_conversion_date       :datetime
#  license_manager_status   :string(1)       default("n"), not null
#  update_manager_status    :string(1)       default("n"), not null
#  updating_subscriptions   :boolean         default(FALSE)
#  major_version            :string(255)
#  minor_version            :string(255)
#  deployed_at              :datetime
#

