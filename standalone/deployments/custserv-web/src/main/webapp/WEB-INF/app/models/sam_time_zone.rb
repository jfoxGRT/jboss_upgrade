class SamTimeZone < ActiveRecord::Base
  acts_as_cached
  set_table_name "sam_time_zone"
end

# == Schema Information
#
# Table name: sam_time_zone
#
#  id             :integer(10)     not null, primary key
#  time_zone_name :string(255)
#  gmt_offset     :text
#

