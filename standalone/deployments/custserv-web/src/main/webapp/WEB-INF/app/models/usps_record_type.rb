class UspsRecordType < ActiveRecord::Base
  acts_as_cached
  set_table_name "usps_record_type"
end

# == Schema Information
#
# Table name: usps_record_type
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

