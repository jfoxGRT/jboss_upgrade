class AddAssignTasksPermission < ActiveRecord::Migration
  def self.up
    scRole = Role.find_by_code("CENTRAL")
    Permission.new(:code => "CUSTSERV-TASKS", :name => "Assign Tasks", :role => scRole).save!
  end

  def self.down
    thePermission = Permission.find_by_code("CUSTSERV-TASKS")
    thePermission.destroy
  end
end
