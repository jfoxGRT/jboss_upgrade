require 'user_manager/defaultDriver'
require 'java'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end

class UsersController < ApplicationController

include UserManager

before_filter :get_current_user, :set_breadcrumb

layout 'default'

def index
  if (params[:sam_customer_id])
    @sam_customer = SamCustomer.find(params[:sam_customer_id])
    @user_term = "Customer Admin"
    conditions_clause = ["sam_customer_id = ? and user_type = ? and active", params[:sam_customer_id], User.TYPE_CUSTOMER]
  else
    @user_term = "Scholastic User"
    conditions_clause = ["user_type != ? and active", User.TYPE_CUSTOMER]
  end
                         
  @users = User.find(:all, :conditions => conditions_clause)
  
  @prototype_required = true
end

def new
  @user = User.new
  @mode = "Add"
  @permissions = Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC, :order => "name")
  @salutations = Salutation.find(:all, :order => "display_order").collect {|s| [s.description, s.id]}
  render(:template => "users/form")
end

def create
  logger.info "params: #{params.to_yaml}"
  # in case the submission is unsuccessful, we want to return to the form with
  # all the information populated again, so we create the @user instance variable
  @permissions = Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC)
  @mode = "Add"
  @salutations = Salutation.find(:all, :order => "display_order").collect {|s| [s.description, s.id]}
  params[:user][:job_title_id] = JobTitle.find_by_code(JobTitle.OTHER_CODE).id
  @user = User.new( params[:user] )
  not_applicable_salutation = Salutation.find_by_code("NA")
  if (not_applicable_salutation.nil?)
    flash[:notice] = "ERROR: Internal required record is not available.&nbsp;&nbsp;Please contact an SAMC administrator"
    redirect_to(new_user_path)
    return
  end
  params[:user][:salutation_id] = not_applicable_salutation.id
  if (!@user.valid?)
  	flash[:notice] = "ERROR: The data you entered was not valid.&nbsp;&nbsp;Please try again."
  	#redirect_to(new_user_path)
  	render(:template => "users/form")
  	return
  end
  # get selected permission ids
  selected = ""

  if params[:permission]
    params[:permission].each_pair {|k, v| selected << (k + "|") if v != "0"}
  end
  
  email = params[:user][:email]
  salutationId = params[:user][:salutation_id]
  firstName = params[:user][:first_name]
  lastName = params[:user][:last_name]
  jobTitleId = params[:user][:job_title_id]
  phone = params[:user][:phone]
  permissionIds = selected
  addedByUserId = @current_user.id

  # prepare request to create a new user. default to the same SAM customer as the current user. 
  logger.info "creating user: #{params[:user][:email]} added by user #{@current_user.email}"
  payload = { :salutation_id => salutationId,
              :added_by_user_id => addedByUserId,
              :user_type => params[:user][:user_type],
              :email => email,
              :first_name => firstName,
              :last_name => lastName,
              :job_title_id => jobTitleId,
              :phone => phone,
              :sam_customer_id => @current_user.sam_customer_id,
              :permission_selected => selected,
              :method_name => "custserv-new-scholastic-user"
            }

  response =  CustServServicesHandler.new.dynamic_new_create_users(request.env['HTTP_HOST'],
                                                   payload,
                                                   CustServServicesHandler::ROUTES['create_edit_delete_user'])
  
  logger.info(">>>>>>>>> response #{response.to_s}")
  if response.type == 'success'
  	flash[:notice] = "Successfully created #{params[:user][:email]}"
  	flash[:msg_type] = "info"
    redirect_to(:action => :index)
  else
    #construct_flash_error_message(result.errorCode)
    flash[:notice] = response.body
    render(:template => "users/form")
  end
end

def show
  @sam_customer = SamCustomer.find(params[:sam_customer_id]) if params[:sam_customer_id]
  @user = User.find(params[:id])
end

def edit
  @user = User.find(params[:id])
  @mode = "Edit"
  ## Do NOT allow "Run Utilities" permission to be managed via website.  This is too powerful a permission
  ##   - This is quick fix; long term fix is is to review all permissions and likely create an ops-user-type that inlcudes only ops staff.
  @permissions = Permission.find(:all, :conditions => ["user_type = (?) and code != ?", User.TYPE_SCHOLASTIC, "RUN-UTILITIES"], :order => "name")
  @salutations = Salutation.find(:all, :order => "display_order").collect {|s| [s.description, s.id]}
  render(:template => "users/form")
end

def update
  # in case the submission is unsuccessful, we want to return to the form with
  # all the information populated again, so we create the @user instance variable
  @user = User.find(params[:user][:id])
  updating_self = (@user == current_user)
  @permissions = Permission.find_all_by_user_type(User.TYPE_SCHOLASTIC)
  @salutations = Salutation.find(:all, :order => "display_order").collect {|s| [s.description, s.id]}
  params[:user][:job_title_id] = JobTitle.find_by_code(JobTitle.OTHER_CODE).id
  @user.attributes=( params[:user] )
  
  # get selected permission ids
  selected = ""

	if params[:permission].nil?
  		@user.permissions.each {|p| selected << (p.id.to_s + "|")}
	else
 		params[:permission].each_pair {|k, v| selected << (k + "|") if v != "0"}
	end
  
  payload = {
              :email =>  params[:user][:email],
              :first_name => params[:user][:first_name],
              :last_name => params[:user][:last_name],
              :phone => params[:user][:phone],
              :job_title_id => params[:user][:job_title_id],
              :salutation_id => params[:user][:salutation_id],
              :user_id => @user.id,
              :method_name => "custserv-edit-scholastic-user"
            }
  # the API handler doesn't like keys with null values
  payload[:user_type] = params[:user][:user_type] unless (params[:user][:user_type].nil? || params[:user][:user_type].empty?)
  
  # API rule is: if the permission_selected param is passed but with no value, all permissions are blown away. if permission_selected
  #              is not present, do not change existing params. the only purpose of having this line below is not not blow away an
  #              admin's permissions with every submit, just in case that admin gets made back into a Scholastic user later.
  payload[:permission_selected] = selected if User.find(params[:user][:id]).isScholasticType
  
  response = CustServServicesHandler.new.dynamic_edit_scholastic_user(request.env['HTTP_HOST'],
                                                                 payload,
                                                                 CustServServicesHandler::ROUTES["create_edit_delete_user"] +
                                                                     "#{@user.id}")
  logger.info(" response >>>>>>>> #{response.to_s}")
  if response.type == "success"
	   flash[:notice] = (updating_self) ? "Updated your profile successfully" : "Updated #{params[:user][:email]} successfully"
	   flash[:msg_type] = "info"
      redirect_to(user_path(@user))
  else
    #construct_flash_error_message(result.errorCode)
    flash[:notice] = response.body
    redirect_to(:action => :edit)
  end
end

def destroy
    # call user manager to delete user
    #userManager = UserManagerPortType.new( USER_MANAGER_URL )
    user = User.find(params[:id])
    param = DeleteScholasticUser.new
    param.userId = params[:id]
    #result = userManager.deleteScholasticUser( param ).out
    payload = {
          "user_id" => user.id,
          "method_name" => "custserv-delete-scholastic-user"
    }
    response = CustServServicesHandler.new.dynamic_edit_scholastic_user(request.env['HTTP_HOST'],
                                                                    payload,
                                                                    CustServServicesHandler::ROUTES['create_edit_delete_user'] +
                                                                    "#{user.id}")
    logger.info("response >>>>>>>>>>>>>> #{response.to_s}")
    if response.type == "success"
    	flash[:notice] = "Deleted #{user.email} successfully"
    	flash[:msg_type] = "info"
      redirect_to( :action => :index )
    else
      raise
    end
  rescue Exception => e
    logger.info(e.to_s)
    flash[:notice] = response.type
    redirect_to(:action => :index)
end



def search
  params[:user][:user_created_at_start_date] ||= ""
  params[:user][:user_created_at_end_date] ||= ""
  params[:user][:registered_at_start_date] ||= ""
  params[:user][:registered_at_end_date] ||= ""
  params[:user].each_pair {|k,v| v.strip!}
  @users = User.search(params[:user])
end

#################
# AJAX ROUTINES #
#################

def update_dock_setting
  dock_setting = DockSetting.find_or_create_by_user_id_and_dock_code(:user_id => current_user.id, :dock_code => params[:dock_code], :status => params[:status].to_i)
  dock_setting.status = params[:status].to_i
  dock_setting.save
  if (params[:dock_code] == DockSetting::CODE_TASKS)
    session[:tasks_dock_status] = params[:status].to_i
  elsif (params[:dock_code] == DockSetting::CODE_SAM_CUSTOMERS)
    session[:sam_customers_dock_status] = params[:status].to_i
  end
  render(:text => "")
end


private

def construct_flash_error_message(error_code)
  case error_code
    when 0 then flash[:notice] = "That email address is already reserved.  Please try again."
    when 3 then flash[:notice] = "That email address is not recognized.  Please try again."
    when 4 then flash[:notice] = "There are still open tasks assigned to this user.  Please revoke all tasks for the user and try again."
    when 5 then flash[:notice] = "Cannot unset the last permission for this user."
    when 6 then flash[:notice] = "That Super Admin user already exists."
    else flash[:notice] = "An error occurred during your request.  Please try again later. (error code = #{error_code})"
  end
end


def get_current_user
  @current_user = current_user
end

def set_breadcrumb
  @site_area_code = CUSTOMER_ADMINS_CODE
end

end
