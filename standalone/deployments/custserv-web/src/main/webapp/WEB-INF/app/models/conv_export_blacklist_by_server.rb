class ConvExportBlacklistByServer < ActiveRecord::Base
  set_table_name "conv_export_blacklist_by_server"
end

# == Schema Information
#
# Table name: conv_export_blacklist_by_server
#
#  id            :integer(10)     not null, primary key
#  sam_server_id :integer(10)     not null
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#

