class SamServerContact < ActiveRecord::Base
  belongs_to :sam_server
  set_table_name "sam_server_contact"
end
