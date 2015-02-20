class SamServerCommunityInfosController < SamServersController
  
  def show
    @sam_customer = @sam_server.sam_customer
    @sam_server_community_info = SamServerCommunityInfo.find(params[:id])
    @sam_server_subcommunity_infos = SamServerSubcommunityInfo.find(:all, :conditions => ["sam_server_community_info_id = ?", params[:id]])
  end
  
end
