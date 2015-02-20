class AgentComponent < ActiveRecord::Base
  set_table_name "agent_component"
  belongs_to :agent
end

# == Schema Information
#
# Table name: agent_component
#
#  id       :integer(10)     not null, primary key
#  agent_id :integer(10)     not null
#  name     :string(255)
#  value    :integer(10)
#

