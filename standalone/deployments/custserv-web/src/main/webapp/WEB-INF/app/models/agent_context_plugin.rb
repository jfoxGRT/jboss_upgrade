class AgentContextPlugin < ActiveRecord::Base
  set_table_name "agent_context_plugin"
  belongs_to :agent_context
end
