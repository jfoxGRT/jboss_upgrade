class AddAdminPermission < ActiveRecord::Migration
  def self.up
    Permission.reset_column_information
    scholastic_perms = Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC)
    admin_users = User.find_all_by_user_type(User.TYPE_ADMIN)
    admin_users.each do |au|
      scholastic_perms.each do |sp|
        UserPermission.create(:user => au, :permission => sp)
      end
    end
  end

  def self.down
    UserPermission.find_all_by_permission_id(Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC).collect {|c| c.id}).each do |up|
      up.destroy if up.user.isAdminType
    end    
  end
  
end
