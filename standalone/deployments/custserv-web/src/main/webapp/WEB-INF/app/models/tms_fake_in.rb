class TmsFakeIn < ActiveRecord::Base
  set_table_name "tms_fake_in"
end

# == Schema Information
#
# Table name: tms_fake_in
#
#  id         :integer(10)     not null, primary key
#  message    :text            not null
#  created_at :datetime
#  priority   :integer(10)     default(0), not null
#

