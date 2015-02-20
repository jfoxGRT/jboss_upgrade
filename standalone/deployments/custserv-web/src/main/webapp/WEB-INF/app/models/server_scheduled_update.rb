class ServerScheduledUpdate < ActiveRecord::Base
  set_table_name "server_scheduled_update"
  belongs_to :scheduled_update
  belongs_to :sam_server
end
