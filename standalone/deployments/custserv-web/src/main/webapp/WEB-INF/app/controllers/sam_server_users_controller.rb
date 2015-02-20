class SamServerUsersController < SamServersController
  
  layout 'default'
  
  def index
    @sam_server_users = SamServerUser.find(:all, :select => "*, type as s_type", :conditions => ["sam_server_id=?", @sam_server.id])
    @sam_customer = @sam_server.sam_customer
  end
  
end
