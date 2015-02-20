require 'java'
import 'java.lang.Integer'
import 'java.util.HashMap'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
require 'user_manager/defaultDriver'

class AccountController < ApplicationController
  
  layout :setlayout
 
  include UserManager

  def index
    redirect_to(:controller => :home, :action => :index)
  end

  def login
   logger.info("session: #{session.to_yaml}")
    if request.post?
      logger.info("in account login (post); session[:return_to] = #{session[:return_to]}")
      self.current_user = User.authenticate(params[:email], params[:password])
      if logged_in?
        if current_user.isCustomerType()
          reset_session
        end
        redirect_back_or_default(url_for(:controller => :home, :action => :index))
        #redirect_to :controller => :home, :action => :index
      else
        flash[:heading] = "Login Error"
      	flash[:notice] = "The email address and password do not match a SAM Connect account.<br/><br/>Please try again or contact a SAMC Administrator."
       	redirect_to :action => :login
       	return
      end
    elsif request.get?
      logger.info("in account login (get); session[:return_to] = #{session[:return_to]}")
      if logged_in?
        session[:return_to] = nil
        redirect_to(:controller => :home, :action => :index)
      end
    end    
  end
  
  def logout
    reset_session
    redirect_to :action => :login
  end
  
  def profile
    if request.get? 
      if logged_in? 
        @user = current_user
      else
        raise "Can't edit profile: not logged in"
      end
    elsif request.post? 
      @user = User.find(params[:user][:id])
      @user.update_attributes( params[:user] )
      flash[:notice] = "Updated Profile"      
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'profile'
  end
  
  def forgot
    if request.post? 
      if !params[:user][:email].nil? && !params[:user][:email].empty?
        @user = User.find_by_email(params[:user][:email])
        if !@user.nil?
          # TODO: re-implement
          #new_password = @user.reset_password
          #@user.save!
          #PasswordRecoveryMailer.deliver_forgot( @user, new_password )
          #flash[:notice] = "Your Password has been Sent to your Email Address"      
          redirect_to :action => "login"
        else
          # TODO: Put this in the user form errors
          flash[:notice] = "Could not locate User with Email Address"            
        end
      else
        # TODO: Put this in the user form errors
        flash[:notice] = "You must supply an email address"
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'forgot'
  end
  
  def reset_password
    flash[:notice] = ""
    logger.info("request post value == #{request.post?}")
    if request.post?
      logger.info("Inside the if now")
      userManager = UserManagerPortType.new( USER_MANAGER_URL )
      param = RequestNewUserPassword.new
      param.email = params[:email]
      logger.info("calling user manager with param: #{param.to_yaml}")
      result = userManager.requestNewUserPassword( param ).out
      logger.info("made it back from user manager call")
      if result.success
        # TODO: add password changed email here
        redirect_to :action => :password_reset_response
      else
        if(params[:email] == nil || params[:email] == "")
	  logger.info "email is empty"
	  flash[:notice] = "Please insert an email address."
	  render :template => "account/reset_password"
        elsif result.errorCode == 3
	  logger.info "email is wrong"
          flash[:notice] = "That email address is not recognized by SAM Connect."
          render :template => "account/reset_password"
        else
          raise
        end
      end
    end
    rescue Exception => e
      flash[:notice] = "An error occurred during your query. Please try again later."
      render :template => "account/reset_password"
  end

  def password_reset_response
  end

  private 
    def setlayout
      logged_in? ? "home" : "account_nonav"
    end  

end
