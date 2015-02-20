class ScheduledUpdate < ActiveRecord::Base
  set_table_name "scheduled_update"
  belongs_to :sam_customer
  belongs_to :sapling
  belongs_to :community
end
