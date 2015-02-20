require 'digest/sha1'

class Agent < ActiveRecord::Base
  set_table_name "agent"
  has_many :conversation_instances
  belongs_to :sam_server
  has_many :agent_components
  has_many :agent_plugins
  has_many :agent_components

  def unignore_agent_date_part
    return (self.unignore_agent_date.nil?) ? "" : self.unignore_agent_date.strftime("%Y-%m-%d")
  end
  
  def unignore_agent_time_part
    return (self.unignore_agent_date.nil?) ? "" : self.unignore_agent_date.strftime("%H:%M:%S")
  end
  
  def poll_override_expires_at_date
    return (self.poll_override_expires_at.nil?) ? "" : self.poll_override_expires_at.strftime("%Y-%m-%d")
  end
  
  def poll_override_expires_at_time
    return (self.poll_override_expires_at.nil?) ? "" : self.poll_override_expires_at.strftime("%H:%M:%S")
  end


  # return a checksum string that custserv users can reference for convenience to verify that a given set of
  # agent versions matches. the intent is that release engineering will adopt the same algorithm in tagging
  # their releases. if that never comes to fruition, this method can be eliminated. algorithm is:
  #   first 32 bits (8 hex characters) of a SHA1 hash of strings of agent versions, alphabetized by plugin code.
  #   example: {core version 220, auth version 40, product-update version 30} => SHA1.hexdigest("4022030")
  def get_plugin_set_checksum
    raw_string = String.new
    
    plugin_set = self.agent_plugins
    unless plugin_set.empty?
      plugin_set.sort! { |a, b| a.name <=> b.name}
      
      plugin_set.each { |plugin| raw_string += plugin.value }
    end
    
    # agent_plugin.value is technically nullable; raw_string could be empty even if plugin_set is non-empty
    raw_string.empty? ? 'none' : Digest::SHA1.hexdigest(raw_string)[0, 8]
  end
  
end

# == Schema Information
#
# Table name: agent
#
#  id                            :integer(10)     not null, primary key
#  created_at                    :datetime        not null
#  updated_at                    :datetime        not null
#  sam_server_id                 :integer(10)
#  cookie                        :string(36)      not null
#  cookie_verified               :boolean
#  jre_version                   :integer(10)
#  microloader_version           :integer(10)
#  next_poll_at                  :datetime
#  os_series                     :string(255)
#  cpu_bits                      :string(255)
#  os_family                     :string(255)
#  cpu_type                      :string(255)
#  last_ip                       :string(255)
#  last_verified_cookie          :string(36)
#  poll_override                 :integer(10)
#  poll_override_expires_at      :datetime
#  last_loop_danger_command_name :string(255)
#  last_loop_danger_command_date :datetime
#  command_chatter_date          :datetime
#  command_chatter_count         :integer(10)     default(0)
#  ignore_agent                  :boolean         default(FALSE)
#  unignore_agent_date           :datetime
#  sapling_digest                :string(255)
#  next_subcmdr_stats_at         :datetime
#  last_subcmdr_reset_at         :datetime
#  express_conversation_waiting  :boolean         default(FALSE), not null
#  current_command_id            :string(255)
#  last_local_ip                 :string(255)
#

