class DropOrgIdUnique < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE sam_server_school_info DROP KEY org_id"
  end

  def self.down
    execute "ALTER TABLE ADD UNIQUE org_id"
  end
end
