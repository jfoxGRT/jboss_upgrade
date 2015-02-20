class SamServerCommunityInfo < ActiveRecord::Base
  set_table_name "sam_server_community_info"
  belongs_to :sam_server  
  has_many :sam_server_subcommunity_infos
  belongs_to :community
end

# == Schema Information
#
# Table name: sam_server_community_info
#
#  id            :integer(10)     not null, primary key
#  community_id  :integer(10)     not null
#  sam_server_id :integer(10)     not null
#  version       :integer(10)
#  updated_at    :datetime        not null
#  created_at    :datetime        not null
#  enabled       :boolean
#

