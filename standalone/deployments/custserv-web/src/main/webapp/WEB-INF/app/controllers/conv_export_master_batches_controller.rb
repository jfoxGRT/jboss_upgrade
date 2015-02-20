require 'java'
import 'java.lang.Integer'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end


@@FIND_MASTER_SQL = "SELECT c.ucn as ucn, sc.name as cust_name, count(distinct ss.name) as num_sam_servers
FROM conversation_instance ci, agent a, sam_server ss, customer c, org o, sam_customer sc, 
conv_export_sub_batch sb, conv_export_master_batch mb
                                                          WHERE mb.id = sb.conv_export_master_batch_id
                                                           AND sb.id = ci.conv_export_sub_batch_id
                                                           AND ci.agent_id = a.id
                                                           AND  a.sam_server_id = ss.id
                                                           AND ss.sam_customer_id  = sc.id
                                                           AND sc.root_org_id = o.id
                                                           AND o.customer_id = c.id
                                                           AND ci.conversation_identifier = 'exec-export-data' 
                                                           AND mb.id = ? "
@@FIND_MASTER_RESTRICT_BY_UCN_CONDITION = "AND c.ucn = ? "
@@FIND_MASTER_GROUP_BY = "GROUP BY c.ucn, sc.name "
@@FIND_MASTER_ORDER_BY = "ORDER BY sc.name "


@@CONV_START_MINS_SELECT_LIST = [['immediately', 0], ['in 1 minute', 1], ['in 5 minutes', 5], ['in 10 minutes', 10], ['in 15 minutes', 15], ['in 30 minutes', 30], ['in 45 minutes', 45], ['in 1 hour', 60]]
@@CONV_WINDOWS_MINS = [['all at once', 0], ['1 minute', 1], ['5 minutes', 5], ['10 minutes', 10], ['20 minutes', 20], ['40 minutes', 40], ['1 hour', 60], ['90 minutes', 90], ['2 hours', 120]]
@@DROPDEAD_WINDOW_MINS = [['1 hour from last conversation', 60], ['2 hours from last conversation', 120], ['3 hours from last conversation', 180], ['4 hours from last conversation', 240], ['5 hours from last conversation', 300], ['6 hours from last conversation', 360], ['7 hours from last conversation', 420], ['8 hours from last conversation', 480], ['9 hours from last conversation', 540], ['10 hours from last conversation', 600], ['11 hours from last conversation', 660], ['12 hours from last conversation', 720]]


class ConvExportMasterBatchesController < ApplicationController


  layout 'default'
  ## layout 'new_layout_with_jeff_stuff'


  # GET /conv_export_master_batches
  # GET /conv_export_master_batches.xml
  def index
    @conv_export_master_batches = ConvExportMasterBatch.find_open

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @conv_export_master_batches }
    end
  end

  # GET /conv_export_master_batches/1
  # GET /conv_export_master_batches/1.xml
  def show
     #@conv_export_master_batch = ConvExportMasterBatch.find(params[:id]);
     #execute_force_publish
     if (url_for(:only_path => true) == "/custserv/conv_export_master_batches/execute_force_publish")
         execute_force_publish
     else
        
        @ucnRedoFailedExportAvailable = false;
        @conv_export_master_batch = ConvExportMasterBatch.find(params[:id]);
    
    
        # fetch the sub batches.  If we're NOT filtering by ucn, this is just ALL the related subbatches
        #  otherwise it's a restricted to the sub batches that have conversations for servers with this ucn
        @my_sub_batches = params[:ucn].nil? ? 
                            @conv_export_master_batch.conv_export_sub_batches : 
                            @conv_export_master_batch.sub_batches_for_ucn(params[:ucn]);
        
        my_sql_array = params[:ucn].nil? ? 
          [  @@FIND_MASTER_SQL + @@FIND_MASTER_GROUP_BY + @@FIND_MASTER_ORDER_BY, params[:id] ]   : 
          [  @@FIND_MASTER_SQL + @@FIND_MASTER_RESTRICT_BY_UCN_CONDITION + @@FIND_MASTER_GROUP_BY + @@FIND_MASTER_ORDER_BY, params[:id], params[:ucn] ]   ;
        @cust_data = ConvExportMasterBatch.find_by_sql( my_sql_array );
    
        ######## begin UCN RESTRICTED ####################################
        if !params[:ucn].nil?
    
          # we are restricting view of this master batch by customer, so get the status of the batch IF the batch we're looking at is the CURRENT batch (ie, it's open)
          if !@conv_export_master_batch.closed
            # get the batch status, as compiled by sam connect
            @batch_status_bean            = SC.getBean("conversationExportBatchService").getCustomerExportBatchStatus(params[:ucn].to_i)
            # Flag that indicates whether we can execute a redo sub batch operation
            @ucnRedoFailedExportAvailable = SC.getBean("conversationExportBatchService").canRedoFailedUcnExportSubbatch(params[:ucn].to_i);
            # flag that indicates whether we can execute a force redo sub batch operation
            @ucnForceRedoExportAvailable  = SC.getBean("conversationExportBatchService").canForceRedoAllUcnExportSubbatch(params[:ucn].to_i);
            #flag that tells us whether there are pending archive reload requests for this UCN, used to hide the partial reload form
            #@ucnHasPendingArchiveReloadRequests  = SC.getBean("conversationExportBatchService").hasPendingArchiveReloadRequests(params[:ucn].to_i);
            # set the lists used to populate select boxes for actions
            @convStartMinsSelectList      = @@CONV_START_MINS_SELECT_LIST;
            @convWindowsMins              = @@CONV_WINDOWS_MINS;
            @dropdeadWindowMins           = @@DROPDEAD_WINDOW_MINS
            # get the status of dashboard for this UCN via dashboard mgmt web api
            @dash_status_bean             = SC.getBean("dashboardCommunicationService").getDashStatusByUcn(params[:ucn].to_i)
          end
    
          #  Also get the ucn name so we can display it in the table header
          if !@cust_data.nil?
            @cust_data.each do |cd|
              if !cd.ucn.nil? && cd.ucn.to_s == params[:ucn] && !cd.cust_name.nil?
                @ucn_name = cd.cust_name ;
              end  
            end   
          end
    
        end
        ######## end UCN RESTRICTED ######################################
    
        respond_to do |format|
          format.html # show.html.erb
          format.xml  { render :xml => @conv_export_master_batch }
        end
     end #JF
  end

  def redoFailedExport
    @subbatchStarterResponseBean = SC.getBean("conversationExportBatchService").redoFailedUcnExportSubbatch(params[:ucn].to_i, params[:conv_start_mins].to_i, params[:conv_window_mins].to_i, params[:dropdead_window_mins].to_i);
    @newSubBatch = @subbatchStarterResponseBean.subbatch;

    flash[:msg] = 'A new Sub batch was created for ucn ' + params[:ucn] + '.  See below.'
    redirect_to :action => :show, :id => params[:master_id], :ucn => params[:ucn]
  end

  def forceRedoAllExportForUcn
    # start the sub-batch and convos, using the force
    @subbatchStarterResponseBean = SC.getBean("conversationExportBatchService").forceRedoAllUcnExportSubbatch(params[:ucn].to_i, params[:conv_start_mins].to_i, params[:conv_window_mins].to_i, params[:dropdead_window_mins].to_i, java.lang.Boolean.new(params[:reNotify]));
    @newSubBatch = @subbatchStarterResponseBean.subbatch;

    flash[:msg] = 'A new force redo Sub batch was created for ucn ' + params[:ucn] + '.  See below.'
    redirect_to :action => :show, :id => params[:master_id], :ucn => params[:ucn]
  end
  
  def forceRedoPartialExportForUcn
    # start the sub-batch and convos, using the force, only redo the exports that have not been loaded for current batch
    renotifyString = params[:partial_reNotify]
    renotifyFlag = nil
    if(!renotifyString.nil? and renotifyString == 'true')
      renotifyFlag = true
    else
      renotifyFlag = false
    end
    logger.info "renotifyFlag: #{renotifyFlag}"
    @subbatchStarterResponseBean = SC.getBean("conversationExportBatchService").forceRedoPartialUcnExportSubbatch(params[:ucn].to_i, params[:partial_conv_start_mins].to_i, params[:partial_conv_window_mins].to_i, params[:partial_dropdead_window_mins].to_i, renotifyFlag);
    @newSubBatch = @subbatchStarterResponseBean.subbatch;
    if(!@newSubBatch.nil?)
      flash[:msg] = 'A new force redo Sub batch was created for ucn ' + params[:ucn] + '.  See below.'
    elsif(@subbatchStarterResponseBean.someArchivesWillBeReloaded)
      flash[:msg] = 'No new sub batch was created.  All servers will load from the archive.'
    else
      flash[:msg] = 'No new force redo Sub batch was created for ucn ' + params[:ucn] + '. No servers will be reloaded from archive. No partial was republish executed.'
    end
    redirect_to :action => :show, :id => params[:master_id], :ucn => params[:ucn]
  end

  def batch_manual_override
  end

  def show_customers
    @conv_export_master_batch = ConvExportMasterBatch.find(params[:id])

    logger.debug "JF: In show_customers"
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @conv_export_master_batch }
    end
  end

  #TODO: Convert to WebAPI - JF
  def is_force_publish_eligible(sam_customer_ucn)
       
      @ucnEligible = SC.getBean("conversationExportBatchService").getEligibleDashboardCustomerUCNs();
      
      if (@ucnEligible.length == 0)
          return false
      else
          @ucnEligible.each do |ucn, ucn2|
              if (ucn.to_s == sam_customer_ucn.to_s)
                  return true
              end
          end
      end
  end

  def is_in_current_master_batch(sam_customer_ucn)                             
     batch_id = ConvExportMasterBatch.find_open[0].id
     in_batch = ConvExportMasterBatch.find(:all, 
                :select => "c.ucn as ucn, sc.name as cust_name, count(distinct ss.name) as num_sam_servers",
                :joins => "mb INNER JOIN conv_export_sub_batch sb on mb.id = sb.conv_export_master_batch_id
                           INNER JOIN conversation_instance ci on sb.id = ci.conv_export_sub_batch_id
                           INNER JOIN agent a on ci.agent_id = a.id
                           INNER JOIN sam_server ss on a.sam_server_id = ss.id
                           INNER JOIN sam_customer sc on ss.sam_customer_id = sc.id
                           INNER JOIN org o on sc.root_org_id = o.id
                           INNER JOIN customer c on o.customer_id = c.id",
                :conditions => ["ci.conversation_identifier = 'exec-export-data' AND mb.id = ? AND c.ucn = ?", batch_id, sam_customer_ucn],
                :group => "c.ucn, sc.name HAVING count(distinct ss.name) > 0")

     in_batch.each do |batch|
         if (batch.ucn.to_s == sam_customer_ucn.to_s)
             return true
         end
     end
     
     return false
  end
  
  def execute_force_publish        
        # Needed for user permission check
        @current_user = User.find(params[:user])
        # Determine if in the current batch
        in_curr_batch = is_in_current_master_batch(params[:ucn])
        # Determine if eligfible for a Dashboard publish
        publish_eligible = is_force_publish_eligible(params[:ucn])
        
        # Conditions:
        # 1) If the user does not have the correct permission, display a message indicating so 
        #    and redirect back
        # 2) If the UCN is in the current master batch, render the relevant batch page for that UCN
        # 3) If the UCN is not eligible for a Dashboard publish, display a message indicating so
        #    and redirect back
        # 4) Otherwise, render the Force Publish Actions table for this UCN
        if (in_curr_batch)
            redirect_to conv_export_master_batch_path(ConvExportMasterBatch.find_open[0].id, :ucn => params[:ucn])
        elsif (!publish_eligible)
            flash[:notice] = 'This customer is not eligible for a Dashboard publish.'
            redirect_to :back
        else        
            #TODO: Put this block in a separate method, and reference from show() - JF
            #TODO: Convert to WebAPI - JF
            
            @ucn = params[:ucn]         
            @sam_customer = SamCustomer.find_by_ucn(@ucn)
            @ucnRedoFailedExportAvailable = false;
            batch_id = ConvExportMasterBatch.find_open[0].id
            @conv_export_master_batch = ConvExportMasterBatch.find(batch_id);
        
            # fetch the sub batches.  If we're NOT filtering by ucn, this is just ALL the related subbatches
            #  otherwise it's a restricted to the sub batches that have conversations for servers with this ucn
            @my_sub_batches = params[:ucn].nil? ? 
                                @conv_export_master_batch.conv_export_sub_batches : 
                                @conv_export_master_batch.sub_batches_for_ucn(params[:ucn]);
            
            my_sql_array = params[:ucn].nil? ? 
              [  @@FIND_MASTER_SQL + @@FIND_MASTER_GROUP_BY + @@FIND_MASTER_ORDER_BY, params[:id] ]   : 
              [  @@FIND_MASTER_SQL + @@FIND_MASTER_RESTRICT_BY_UCN_CONDITION + @@FIND_MASTER_GROUP_BY + @@FIND_MASTER_ORDER_BY, params[:id], params[:ucn] ]   ;
            @cust_data = ConvExportMasterBatch.find_by_sql( my_sql_array );
        
            ######## begin UCN RESTRICTED ####################################
            if !params[:ucn].nil?
        
              # we are restricting view of this master batch by customer, so get the status of the batch IF the batch we're looking at is the CURRENT batch (ie, it's open)
              if !@conv_export_master_batch.closed
                # get the batch status, as compiled by sam connect
                @batch_status_bean            = SC.getBean("conversationExportBatchService").getCustomerExportBatchStatus(params[:ucn].to_i)
                # Flag that indicates whether we can execute a redo sub batch operation
                @ucnRedoFailedExportAvailable = SC.getBean("conversationExportBatchService").canRedoFailedUcnExportSubbatch(params[:ucn].to_i);
                # flag that indicates whether we can execute a force redo sub batch operation
                @ucnForceRedoExportAvailable  = SC.getBean("conversationExportBatchService").canForceRedoAllUcnExportSubbatch(params[:ucn].to_i);
                #flag that tells us whether there are pending archive reload requests for this UCN, used to hide the partial reload form
                #@ucnHasPendingArchiveReloadRequests  = SC.getBean("conversationExportBatchService").hasPendingArchiveReloadRequests(params[:ucn].to_i);
                # set the lists used to populate select boxes for actions
                @convStartMinsSelectList      = @@CONV_START_MINS_SELECT_LIST;
                @convWindowsMins              = @@CONV_WINDOWS_MINS;
                @dropdeadWindowMins           = @@DROPDEAD_WINDOW_MINS
                # get the status of dashboard for this UCN via dashboard mgmt web api
                @dash_status_bean             = SC.getBean("dashboardCommunicationService").getDashStatusByUcn(params[:ucn].to_i)
              end
        
              #  Also get the ucn name so we can display it in the table header
              if !@cust_data.nil?
                @cust_data.each do |cd|
                  if !cd.ucn.nil? && cd.ucn.to_s == params[:ucn] && !cd.cust_name.nil?
                    @ucn_name = cd.cust_name ;
                  end  
                end   
              end
            end
    
        end
        ######## end UCN RESTRICTED ######################################
        
  end
  

  # GET /conv_export_master_batches/new
  # GET /conv_export_master_batches/new.xml
  def new
    @conv_export_master_batch = ConvExportMasterBatch.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @conv_export_master_batch }
    end
  end

  # GET /conv_export_master_batches/1/edit
  def edit
    @conv_export_master_batch = ConvExportMasterBatch.find(params[:id])
  end

  # POST /conv_export_master_batches
  # POST /conv_export_master_batches.xml
  def create
    @conv_export_master_batch = ConvExportMasterBatch.new(params[:conv_export_master_batch])

    respond_to do |format|
      if @conv_export_master_batch.save
        flash[:notice] = 'ConvExportMasterBatch was successfully created.'
        format.html { redirect_to(@conv_export_master_batch) }
        format.xml  { render :xml => @conv_export_master_batch, :status => :created, :location => @conv_export_master_batch }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @conv_export_master_batch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /conv_export_master_batches/1
  # PUT /conv_export_master_batches/1.xml
  def update
    @conv_export_master_batch = ConvExportMasterBatch.find(params[:id])

    respond_to do |format|
      if @conv_export_master_batch.update_attributes(params[:conv_export_master_batch])
        flash[:notice] = 'ConvExportMasterBatch was successfully updated.'
        format.html { redirect_to(@conv_export_master_batch) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @conv_export_master_batch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /conv_export_master_batches/1
  # DELETE /conv_export_master_batches/1.xml
  def destroy
    @conv_export_master_batch = ConvExportMasterBatch.find(params[:id])
    @conv_export_master_batch.destroy

    respond_to do |format|
      format.html { redirect_to(conv_export_master_batches_url) }
      format.xml  { head :ok }
    end
  end
  
  
  def open_master_batch_sam_customers
    logger.debug "JF: In open_master_batch_sam_customers"
    our_desc = "%" + params[:term] + "%"
    sam_customers = SamCustomer.find_by_sql(["SELECT distinct(c.ucn) as samc_ucn, trim(sc.name) as label, trim(sc.name) as value, sp.code as state_province_code, sp.name as state_province_name
    FROM conversation_instance ci, agent a, sam_server ss, customer c, customer_address ca, address_type atype, state_province sp, org o, sam_customer sc, conv_export_sub_batch sb, conv_export_master_batch mb
    WHERE mb.id = sb.conv_export_master_batch_id 
    AND sb.id = ci.conv_export_sub_batch_id 
    AND ci.agent_id = a.id 
    AND a.sam_server_id = ss.id 
    AND ss.sam_customer_id  = sc.id 
    AND sc.root_org_id = o.id 
    AND o.customer_id = c.id 
    AND ca.customer_id = c.id 
    AND ca.address_type_id = atype.id 
    AND atype.code = '05'
    AND ca.state_province_id = sp.id 
    AND ci.conversation_identifier = 'exec-export-data' 
    AND mb.id = ? 
    AND (sc.name LIKE ?) ORDER BY sc.name LIMIT 50", params[:id], our_desc])
    logger.info("sam_customers: #{sam_customers.to_json}")
    render (:text => sam_customers.to_json)
  end
  
  
  
end
