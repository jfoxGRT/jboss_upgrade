class LicenseCountType < ActiveRecord::Base
  acts_as_cached
  set_table_name "license_count_type"
end

# == Schema Information
#
# Table name: license_count_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

