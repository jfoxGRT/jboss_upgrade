class RenameAddScholasticUserPermission < ActiveRecord::Migration
  def self.up
    aPermission = Permission.find_by_code("CUSTSERV-ADD_S_USER")
    aPermission.code = "MANAGE_S_USERS"
    aPermission.name = "Manage Scholastic Users"
    aPermission.save!
  end

  def self.down
  end
end
