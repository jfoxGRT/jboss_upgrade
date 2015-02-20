class AgentContext < ActiveRecord::Base
  set_table_name "agent_context"
  belongs_to :agent
  has_many :agent_context_plugins
  has_one :agent_context_platform
end
