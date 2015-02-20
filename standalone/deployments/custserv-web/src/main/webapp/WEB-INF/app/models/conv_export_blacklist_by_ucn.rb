class ConvExportBlacklistByUcn < ActiveRecord::Base
  set_table_name "conv_export_blacklist_by_ucn"

end

# == Schema Information
#
# Table name: conv_export_blacklist_by_ucn
#
#  id         :integer(10)     not null, primary key
#  ucn        :integer(10)     not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

