class EmailApprovalController < ApplicationController

  layout 'cs_layout'

  def index
    redirect_to :action => :unapproved
  end
  
  def unapproved
    @unapproved = EmailMessage.find(:all, :conditions => "sent_date is null and approved_date is null", :order => "generated_date desc")
  end
  
  def approve
    approved = {}
    update_val = {"approved_date" => Time.new}
    params[:email].each_pair {|k, v| approved[k] = update_val unless v == "0" }
    EmailMessage.update(approved.keys, approved.values)
    flash[:notice] = "#{approved.size} email message/s approved"
    redirect_to :action => :unapproved
  end
  
end
