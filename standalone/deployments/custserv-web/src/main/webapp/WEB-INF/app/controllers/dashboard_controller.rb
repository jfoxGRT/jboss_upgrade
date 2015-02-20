require 'java'
import 'java.lang.Integer'
import 'java.text.SimpleDateFormat'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end


class DashboardController < ApplicationController

  layout 'default'

  def show_dash_hist
    @dash_load_bean_list = SC.getBean("dashboardCommunicationService").getDashLoadHistory(params[:master_batch_id].to_i, params[:ucn].to_i)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dash_load_bean_list }
    end
  end


  def show_dash_stretch_fails
    @dash_fail_stretch_list = SC.getBean("dashboardCommunicationService").getDashboardNonCompleteStretchFetchHistory(params[:master_batch_id].to_i)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dash_fetch_bean_list }
    end
  end

  def show_dash_fetch_history
    @dash_fetch_list = SC.getBean("dashboardCommunicationService").getDashboardFetchHistoryForUcn(params[:master_batch_id].to_i, params[:ucn].to_i)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dash_fetch_list }
    end
  end


  def show_dash_customers
    @dash_cust_bean_list = SC.getBean("dashboardCommunicationService").getDashStatusAllUcns()

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dash_cust_bean_list }
    end
  end

  def goto_sam_cust_via_ucn
    sam_customer = SamCustomer.find_by_ucn(params[:ucn])
    redirect_to :action => :show, :id => sam_customer.id, :controller => :sam_customers
  end
  
  def batch_manual_override
    redirect_to(:controller => :home, :action => :index) if !@current_user.isAdminType
    
    current_open_master_batch = ConvExportMasterBatch.find_most_recent_open
    @is_new_manual_override_allowed = (current_open_master_batch.nil? || current_open_master_batch.is_dropped_dead?)
    
    @current_time_zone = Time.now.zone
  end
  
  def post_batch_manual_override
    logger.info("our params are: #{params.to_yaml}")
    if (params[:conv_start_date].strip.empty? || params[:conv_end_date].strip.empty? || 
        params[:export_date_range_4w_begin].strip.empty? || params[:export_date_range_end].strip.empty? ||
        params[:export_date_range_1w_begin].strip.empty? || params[:drop_dead_date].strip.empty?)
        flash[:notice] = "One or more fields is invalid"
        render(:template => "dashboard/batch_manual_override")
    else
      # parse dates from the form as payload to the rest service
      payload = {
          "exportDateRange1wBegin"  => "#{params[:export_date_range_1w_begin]}",
          "exportDateRange4wBegin"  => "#{params[:export_date_range_4w_begin]}",
          "exportDateRangeEnd"      => "#{params[:export_date_range_end]}",
          "convStartDate"           => "#{params[:conv_start_date]}",
          "convEndDate"             => "#{params[:conv_end_date]}",
          "dropDeadDate"            => "#{params[:drop_dead_date]}"
      }
      # spawn a separate thread to call a rest service for the batch override
      Thread.new do
        response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                              payload,
                                                                              CustServServicesHandler::ROUTES['manual_batch_override_web_services'])
      end
      
      flash[:notice] = "Manual Batch Override request submitted. Refresh this page in 20 minutes to verify new batch creation."
      flash[:msg_type] = "info"
      redirect_to(:action => :index, :controller => :conv_export_master_batches)
    end
  rescue Exception => e
    logger.info("ERROR: exception caught while attempting to create manual batch override: #{e}")
    flash[:notice] = "ERROR: #{e}"
    redirect_to(:action => :batch_manual_override)
  end

end
