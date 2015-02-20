class AgentContextPlatform < ActiveRecord::Base
  set_table_name "agent_context_platform"
  belongs_to :agent_context
end
