class AddEditUserPermission < ActiveRecord::Migration
  def self.up
    scRole = Role.find_by_code("CENTRAL")
    Permission.new(:code => "CUSTSERV-EDIT", :name => "Edit", :role => scRole).save!
    Permission.new(:code => "CUSTSERV-ADD_S_USER", :name => "Add Scholastic User", :role => scRole).save!
  end

  def self.down
    thePermission = Permission.find_by_code("CUSTSERV-EDIT")
    thePermission.destroy if !thePermission.nil?
    thePermission = Permission.find_by_code("CUSTSERV-ADD_S_USER")
    thePermission.destroy if !thePermission.nil?
  end
end
