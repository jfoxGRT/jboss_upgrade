class LicenseDuration < ActiveRecord::Base
  acts_as_cached
  set_table_name "license_duration"
  
  def self.perpetual
    LicenseDuration.find_by_code("P")
  end
  
end

# == Schema Information
#
# Table name: license_duration
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

