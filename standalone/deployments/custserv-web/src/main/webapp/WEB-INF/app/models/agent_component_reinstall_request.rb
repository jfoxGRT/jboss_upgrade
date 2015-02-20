class AgentComponentReinstallRequest < ActiveRecord::Base
  
  set_table_name "agent_component_reinstall_request"
  
  belongs_to :agent
  
end