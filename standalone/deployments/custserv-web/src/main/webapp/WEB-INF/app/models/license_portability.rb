class LicensePortability < ActiveRecord::Base
  acts_as_cached
  set_table_name "license_portability"
  
  def self.transferrable
    LicensePortability.find_by_code("T")
  end
  
end

# == Schema Information
#
# Table name: license_portability
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

