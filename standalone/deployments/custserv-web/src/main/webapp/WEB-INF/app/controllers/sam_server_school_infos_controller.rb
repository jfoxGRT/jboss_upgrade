class SamServerSchoolInfosController < SamServersController
    
  def index
    @sam_server_school_infos = SamServerSchoolInfo.find_all_by_sam_server_id(@sam_server.id)
  end
  
  def show
    @sam_server_school_info = SamServerSchoolInfo.find(params[:id])
  end

end
