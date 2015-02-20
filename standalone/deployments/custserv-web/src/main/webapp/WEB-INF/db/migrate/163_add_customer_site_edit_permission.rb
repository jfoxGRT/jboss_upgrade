class AddCustomerSiteEditPermission < ActiveRecord::Migration
  def self.up
    custservEditCustomerSite = Permission.create(:code => "CUSTSERV-EDIT-CUSTOMER-SITE", :name => "Customer Site Edit", :user_type => 's')
    admin_users = User.find_all_by_user_type(User.TYPE_ADMIN)
    admin_users.each do |au|
      UserPermission.create(:user => au, :permission => custservEditCustomerSite)
    end
  end

  def self.down
    UserPermission.find_all_by_permission_id((Permission.find_by_code("CUSTSERV-EDIT-CUSTOMER-SITE")).id).each do |up|
      up.destroy if up.user.isAdminType
    end
  end
end
