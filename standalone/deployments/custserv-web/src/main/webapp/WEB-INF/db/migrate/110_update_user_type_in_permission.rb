class UpdateUserTypeInPermission < ActiveRecord::Migration
  def self.up
    assignTask = Permission.find_by_code("CUSTSERV-TASKS")
    edit = Permission.find_by_code("CUSTSERV-EDIT")
    addScholasticUser = Permission.find_by_code("CUSTSERV-ADD_S_USER")
    
    assignTask.user_type = 's'
    edit.user_type = 's'
    addScholasticUser.user_type = 's'
    
    assignTask.save!
    edit.save!
    addScholasticUser.save!
    
  end

  def self.down
    assignTask = Permission.find_by_code("CUSTSERV-TASKS")
    edit = Permission.find_by_code("CUSTSERV-EDIT")
    addScholasticUser = Permission.find_by_code("CUSTSERV-ADD_S_USER")
    
    assignTask.user_type = 'c'
    edit.user_type = 'c'
    addScholasticUser.user_type = 'c'
    
    assignTask.save!
    edit.save!
    addScholasticUser.save!
  end
end
