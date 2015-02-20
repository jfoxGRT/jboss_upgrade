class ExternalController < ApplicationController

	def tms
		# look for a matching scholastic user, first in the parameters; otherwise, in the session
		logger.info("session: #{session.to_yaml}")
		tms_user = User.find_by_tms_userid(params[:tms_userid])
		tms_user = User.find_by_tms_userid(session[:tms_userid]) if tms_user.nil? && !session[:tms_userid].nil?
		logger.info("found matching user of: #{tms_user.to_yaml}")
		# if no matching user is found..
		if (tms_user.nil?)
			# if the user is not logged in..
			if (!logged_in?)
				validate_request
				cache_params
				# save this location
				store_location
				# make sure the user logs in
				flash[:notice] = "Please register your TMS account by entering your SAM Connect username and password.  You will only need to do this once."
				redirect_to(:controller => :account, :action => :login)
			# otherwise, the user IS logged in, but there isn't any binding yet..
			else
				# bind the TMS user ID to our SAMC user
				self.current_user.tms_userid = session[:tms_userid]
				self.current_user.save
				morph_and_redirect(self.current_user, session[:tms_ucn], session[:redirect_url])
			end
		# otherwise, a matching user was found..
		else
			self.current_user = tms_user
			validate_request
			morph_and_redirect(self.current_user, params[:ucn], params[:redirect_url])
		end
	rescue Exception => e
		logger.info("Cannot process TMS request: #{e}")
		redirect_to(:controller => :home, :action => :index)
	end
	
	
	def decommission_licenses
		redirect_to(unassigned_pending_license_count_changes_path(:product_id => params[:product_id]), :ucn => params[:ucn])
	end
	
	
	private
	
	def validate_request
		#raise TmsRequestException("Invalid HTTP method") if request.method.to_s != "post"
		raise TmsRequestException.new("Missing required parameter") if params[:tms_userid].nil? || params[:redirect_url].nil? || params[:ucn].nil?
	end
	
	def morph_and_redirect(p_user, ucn, redirect_url)
		customer = Customer.find_by_ucn(ucn)
		raise TmsRequestException.new("Invalid UCN") if customer.nil?
		sam_customer = customer.org.sam_customer
		raise TmsRequestException.new("No matching SAM EE Customer") if sam_customer.nil?
		# set session variable
		session[:from_tms] = request.url.to_s
		# morph
		p_user.sam_customer = sam_customer
		p_user.save
		# redirect
		redirect_to(redirect_url)
	end
	
	
	def cache_is_clean?
		(!session[:tms_userid].nil?) && (!session[:tms_ucn].nil?) && (session[:tms_userid] == params[:tms_userid]) && (session[:tms_ucn] == params[:ucn])
	end
	
	def cache_params
		session[:tms_userid] = params[:tms_userid]
		logger.info("Missing tms_userid param while storing in session") if params[:tms_userid].nil?
		session[:tms_ucn] = params[:ucn]
		logger.info("Missing ucn param while storing in session") if params[:ucn].nil?
		session[:redirect_url] = params[:redirect_url]
		logger.info("Missing redirect_url param while storing in session") if params[:redirect_url].nil?
	end

end

class TmsRequestException < Exception
	
	attr_accessor :reason
	
	def initialize(reason)
		@reason = reason		
	end
	
	def to_s
		self.reason
	end
	
end