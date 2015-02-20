class LmConversionBlacklistsController < ApplicationController
  
  def index
    @whitelist = SamCustomer.find(:all, :select => "sc.*, c.ucn", :joins => "sc inner join org on sc.root_org_id = org.id
                                                                      inner join customer c on org.customer_id = c.id
                                                                      left join lm_conversion_blacklist lmcb on lmcb.sam_customer_id = sc.id",
                                  :conditions => "lmcb.id is null", :order => "sc.name")
    render(:layout => "cs_blank_layout")
  end
  
  def create
    @failure = false
    logger.info("in create method")
    @sam_customer = SamCustomer.find(params[:id])
    if !@sam_customer.nil?
      LmConversionBlacklist.create(:sam_customer => @sam_customer)
    else
      flash[:notice] = "Invalid SAM EE Customer UCN"
      @failure = true
    end
  end
  
  def destroy
    @failure = false
    @whitelist_entry = SamCustomer.find(:first, :select => "sc.*, c.ucn", :joins => "sc inner join org on sc.root_org_id = org.id
                                                                      inner join customer c on org.customer_id = c.id",
                                  :conditions => ["c.ucn = ?", params[:sam_customer_ucn]])
    if !@whitelist_entry.nil? && !@whitelist_entry.lm_conversion_blacklist.nil?
        @whitelist_entry.lm_conversion_blacklist.delete
    else
      flash[:notice] = "Can't add duplicate entry to the inclusion list."
      @failure = true
    end
  end  
  
end
