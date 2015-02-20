class RemoveUniqueConstraintOnOrgCol < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE sam_server_school_info CHANGE org_id org_id int(11) null"
  end

  def self.down
  end
end
