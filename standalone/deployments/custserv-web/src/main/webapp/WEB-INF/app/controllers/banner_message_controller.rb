class BannerMessageController < ApplicationController
  
  layout "default_with_utilities_subtabs"
  
  def index
        @banner_message = BannerMessage.find(:all, :select => "bm.*, sbm.message_type_description, users.email, users.first_name, users.last_name", 
                                                   :joins => "bm, slms_banner_message sbm, users", 
                                                   :conditions => ["bm.is_historical = false && bm.slms_message_type_code = sbm.message_type_code && bm.creator = users.id"])
        @banner_message_hist = BannerMessage.find(:all, :select => "bm.*, sbm.message_type_description, users.email", 
                                                   :joins => "bm, slms_banner_message sbm, users", 
                                                   :conditions => ["bm.is_historical = true && bm.slms_message_type_code = sbm.message_type_code && bm.creator = users.id"])
        @slms_list = SlmsBannerMessage.find(:all)
        @list = BannerMessageBlacklist.find(:all, :select => "bmb.*, sc.name, sc.name as ucn", 
                                                   :joins => "bmb, sam_customer sc", 
                                                   :conditions => ["bmb.sam_customer_id = sc.id"])
        @list.each do |l|
          l.ucn = Customer.find_ucn_by_sam_customer_id(l.sam_customer_id).ucn.to_s
        end
        
        @active = BannerMessage.count(:all, :conditions => ["is_historical = false && end_datetime > ? && start_datetime <= ?", Time.now, Time.now])
        @pending = BannerMessage.count(:all, :conditions => ["is_historical = false && end_datetime > ? && start_datetime > ?", Time.now, Time.now])                                                                                     
  end  
    
  def add_to_blacklist
    ucn = params[:customer_number]
    begin
      blacklist_record = BannerMessageBlacklist.new
      sam_cust_num = SamCustomer.find_by_ucn(ucn)
      blacklist_record.sam_customer_id = sam_cust_num.id
      blacklist_record.save  
    
      flash[:notice] = ucn + " has been blacklisted from banner messaging."
      redirect_to(:action => :index)
    end
    rescue ActiveRecord::ActiveRecordError
        logger.info "ERROR saving record to database"
        flash[:notice] = "ERROR: " + ucn + " is not a valid customer number."
        redirect_to(:action => :index)
    rescue Exception => msg
        logger.info "ERROR creating blacklist record: " + msg
        flash[:notice] = "ERROR: " + ucn + " is not a valid customer number."
        redirect_to(:action => :index)            
  end
 
  def edit_message
    @banner_message = BannerMessage.find(params[:id])
    @slms_list = SlmsBannerMessage.find(:all)
    ucns = CustomerBannerMessage.find(:all, :conditions => ["banner_message_id = ?", params[:id]])
    @ucnlist = Array.new
    ucns.each do |u|
      @ucnlist << Customer.find_ucn_by_sam_customer_id(u.sam_customer_id).ucn.to_s
    end 
    render(:partial => "edit")
  end
  
  def historical_messages
    @banner_message_hist = BannerMessage.find(:all, :select => "bm.*, sbm.message_type_description, users.email, users.first_name, users.last_name", 
                                                   :joins => "bm, slms_banner_message sbm, users", 
                                                   :conditions => ["bm.is_historical = true && bm.slms_message_type_code = sbm.message_type_code && bm.creator = users.id"]) 
    render(:template => "banner_message/historical_messages")
  end
  
  def view_message
    @banner_message = BannerMessage.find(:first, :select => "bm.*, sbm.message_type_description, users.email, users.first_name, users.last_name", 
                                                   :joins => "bm, slms_banner_message sbm, users", 
                                                   :conditions => ["bm.slms_message_type_code = sbm.message_type_code && bm.creator = users.id && bm.id = ?",params[:id]])
    @slms_list = SlmsBannerMessage.find(:all)
    ucns = CustomerBannerMessage.find(:all, :conditions => ["banner_message_id = ?", params[:id]])
    @ucnlist = Array.new
    ucns.each do |u|
      @ucnlist << Customer.find_ucn_by_sam_customer_id(u.sam_customer_id).ucn.to_s
    end 
    if (@banner_message.is_historical == true)
      @is_subpage = true
    else
     @is_subpage = false  
    end
    render(:partial => "view_message", :locals => {:is_subpage => @is_subpage})
    
  end
    
  def delete_banner_message
    BannerMessage.destroy(params[:id])     
    redirect_to(:action => :index)
     
  end
  
  def hide_banner_message
    banner_message = BannerMessage.first(:conditions => ["banner_message.id = ?", params[:id]])
    banner_message.end_datetime = Time.now
    banner_message.updated_at = Time.now    
    banner_message.save
    
    redirect_to(:action => :index)
    
  end
  
  def post_banner_message
     
     banner_message = BannerMessage.new
     banner_message.message_name = params[:message_name]
     banner_message.created_at = Time.now
     banner_message.updated_at =Time.now
     banner_message.last_posted = Time.now
     if(params[:start_date])
       st = params[:start_time]       
       startdatetime = Time.parse(params[:start_date] + " " + st[:hour].to_s + ":" + st[:minute].to_s)
       banner_message.start_datetime = startdatetime
     end
     if(params[:end_date])
       et = params[:end_time]       
       enddatetime = Time.parse(params[:end_date] + " " + et[:hour].to_s + ":" + et[:minute].to_s)
       banner_message.end_datetime = enddatetime
     end
     banner_message.message = params[:message]
     banner_message.post_to_sam_client = false
     banner_message.post_to_dashboard  = false
     banner_message.post_to_studentaccess = false
     banner_message.post_to_educatoraccess = false
     banner_message.post_to_scholasticcentral = false  

     if (params[:samclient])
      banner_message.post_to_sam_client = true
     end 
     if (params[:dashboards]) 
      banner_message.post_to_dashboard  = true
     end 
     if (params[:studentaccess]) 
      banner_message.post_to_studentaccess = true
     end 
     if (params[:educatoraccess])
      banner_message.post_to_educatoraccess = true
     end 
     if (params[:scholasticcentral])
      banner_message.post_to_scholasticcentral = true
     end 
     
     banner_message.distribution_scope = params[:ucn]
     
     if (params[:server_scope])
      banner_message.server_scope = params[:server_scope]
     end
     
     banner_message.creator = current_user
     banner_message.is_historical = false
     
     slms = SlmsBannerMessage.find(params[:slms_code])
     banner_message.slms_message_type_code = slms.message_type_code
     banner_message.save
     
     lastBanner = BannerMessage.last
     
     if (lastBanner.distribution_scope == 'BY_CUSTOMER')
       ucn_list = params[:ucn_string].split(',')
       ucn_list.each do |ul|
          cbm_record = CustomerBannerMessage.new
          sam_customer = SamCustomer.find_by_ucn(ul)
          if(!sam_customer.nil?)
            cbm_record.sam_customer_id = sam_customer.id
            cbm_record.banner_message_id = lastBanner.id
            cbm_record.save
          else
            lastBanner.destroy
            flash[:notice] = ul.to_s + " is not a valid UCN." 
          end   
       end
     end
              
    redirect_to(:action => :index)   
  end
  
  def remove_blacklist_customer
    BannerMessageBlacklist.delete(BannerMessageBlacklist.first(:conditions => ["sam_customer_id = ?", params[:id]]))     
    redirect_to(:action => :index)    
  end  
  
  def update_banner_message
    banner_message_parent = BannerMessage.first(:conditions => ["banner_message.id = ?", params[:id]])
    #compare inbound params to banner_message fields
    banner_message = BannerMessage.new
    banner_message.message_name = banner_message_parent.message_name
    banner_message.created_at = banner_message_parent.created_at
    banner_message.updated_at =Time.now
     banner_message.last_posted = Time.now
     if(params[:start_date])
       st = params[:start_time]       
       startdatetime = DateTime.parse(params[:start_date] + " " + st[:hour].to_s + ":" + st[:minute].to_s)
       banner_message.start_datetime = startdatetime
     end
     if(params[:end_date])
       et = params[:end_time]       
       enddatetime = DateTime.parse(params[:end_date] + " " + et[:hour].to_s + ":" + et[:minute].to_s)
       banner_message.end_datetime = enddatetime
     end
     banner_message.message = params[:message]
     
     if (params[:samclient])
        banner_message.post_to_sam_client = true
     else
        banner_message.post_to_sam_client = false
     end 
     if (params[:dashboards]) 
        banner_message.post_to_dashboard  = true
     else
        banner_message.post_to_dashboard  = false
     end 
     if (params[:studentaccess]) 
        banner_message.post_to_studentaccess = true
     else
        banner_message.post_to_studentaccess = false
     end 
     if (params[:educatoraccess])
        banner_message.post_to_educatoraccess = true
     else
        banner_message.post_to_educatoraccess = false
     end 
     if (params[:scholasticcentral])
        banner_message.post_to_scholasticcentral = true
     else
        banner_message.post_to_scholasticcentral = false 
     end 
     
     banner_message.distribution_scope = params[:ucn]
     
     if (params[:server_scope])
      banner_message.server_scope = params[:server_scope]
     end
     
     banner_message.creator = current_user
     banner_message.is_historical = false
     banner_message.slms_message_type_code = params[:slms_code]
     #set the original message to a historical message
     banner_message_parent.is_historical = true
     banner_message.save
     banner_message_parent.save
     
     if (banner_message.distribution_scope == 'BY_CUSTOMER')
       updated_ucn_list = params[:ucn_string].split(',')
       updated_ucn_list.each do |ul|
          cbm_record = CustomerBannerMessage.new
          sam_customer = SamCustomer.find_by_ucn(ul)
          if(!sam_customer.nil?)
            cbm_record.sam_customer_id = sam_customer.id
            cbm_record.banner_message_id = banner_message.id
            cbm_record.save
          else
            flash[:notice] = "Message not updated, " + ul.to_s + " is not a valid UCN." 
          end
       end    
     end
     redirect_to(:action => :index)
  end
  
  def validUCN
    logger.info("validUCN method")
    ucn_list = params[:ucn_input].split(/,/)
    @valid_list = []
    @invalid_list = []
    ucn_list.each do |ul|
      begin
        temp = SamCustomer.find_by_ucn(Integer(ul))
      rescue ArgumentError
         logger.info(ul + " is not a valid UCN.")
      end     
      if (!temp.nil?)
        @valid_list << ul
      else
        @invalid_list << ul
      end
      temp = nil
    end
    @ucns = @valid_list.map { |v| {:valid => v} } + @invalid_list.map { |i| {:invalid => i}}
    logger.info(@ucns.to_json)
    render(:json => @ucns)
    
  end
  
end