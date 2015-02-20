require 'fastercsv'

class ConvExportSubBatchesController < ApplicationController

  layout 'default'
  ##  layout 'new_layout_with_jeff_stuff'


  # GET /conv_export_sub_batches
  # GET /conv_export_sub_batches.xml
  def index
    @conv_export_sub_batches = ConvExportSubBatch.find_open

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @conv_export_sub_batches }
    end
  end

  # GET /conv_export_sub_batches/1
  # GET /conv_export_sub_batches/1.xml
  def show
    @conv_export_sub_batch = ConvExportSubBatch.find(params[:id])

    if (!params[:ucn].nil?) 
      session[:conv_export_sub_batch_ucn] = params[:ucn]
    end
    session[:conv_export_sub_batch_id] = params[:id]

    my_conditions = (params[:ucn].nil?) ? ["ci.conv_export_sub_batch_id = ?", params[:id]] : ["ci.conv_export_sub_batch_id = ? and c.ucn = ?", params[:id], params[:ucn]]  ;

    @conv_data_list = ConversationInstance.find(:all, 
                                                :select => "c.ucn ucn, sc.root_org_id, sc.id sam_customer_id, sc.name cust_name, ss.id sam_server_id, ss.name sam_server_name, a.id agent_id,
                                                            ci.id conversation_instance_id, date_format(ci.created_at, '%H:%i:%S %m/%d/%Y') conversation_create_date, 
                                                            date_format(ci.started, '%H:%i:%S %m/%d/%Y') conversation_start_date, 
                                                            date_format(ci.completed, '%H:%i:%S %m/%d/%Y') conversation_completed, 
                                                            ci.embargo_until embargo_until, ci.expiration_date expiration_date, 
                                                            ci.async_activity_id, aast.name async_activity_status_name, 
                                                            crt.code conversation_result_code, crt.name conversation_result_name,
                                                            date_format(aa.handled_on, '%H:%i:%S %m/%d/%Y') async_activity_handled_on", 
                                                :joins =>  "ci inner join conversation_result_type crt on ci.result_type_id = crt.id
                                                            inner join agent a on ci.agent_id = a.id
                                                            inner join sam_server ss on ss.id = a.sam_server_id
                                                            inner join sam_customer sc on sc.id = ss.sam_customer_id
                                                            inner join org o on o.id = sc.root_org_id
                                                            inner join customer c on c.id = o.customer_id
                                                            left join async_activity aa on (aa.id = ci.async_activity_id)
                                                            left join async_activity_status_type aast on aast.id = aa.status_id",
                                                :conditions => my_conditions, 
                                                :order => "sc.name ASC, ss.name ASC, ci.created_at ASC");
    @ucnmap = Hash.new(0);
    if !@conv_data_list.nil?
      @conv_data_list.each do |conv_data|
        if !@ucnmap.has_key?(conv_data.ucn)
          @ucnmap[conv_data.ucn] = conv_data.cust_name;
        end  
      end   
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @conv_export_sub_batch }
    end
  end

  def export_conv_export_sub_batches_to_csv
    logger.info "EXPORTING CSV"
    my_conditions = (session[:conv_export_sub_batch_ucn].nil?) ? ["ci.conv_export_sub_batch_id = ?", session[:conv_export_sub_batch_id]] : ["ci.conv_export_sub_batch_id = ? and c.ucn = ?", session[:conv_export_sub_batch_id], session[:conv_export_sub_batch_ucn]]  ;

    @conv_data_list = ConversationInstance.find(:all, 
                                                :select => "c.ucn ucn, sc.root_org_id, sc.id sam_customer_id, sc.name cust_name, ss.id sam_server_id, ss.name sam_server_name, a.id agent_id,
                                                            ci.id conversation_instance_id, date_format(ci.created_at, '%H:%i:%S %m/%d/%Y') conversation_create_date, 
                                                            date_format(ci.started, '%H:%i:%S %m/%d/%Y') conversation_start_date, 
                                                            date_format(ci.completed, '%H:%i:%S %m/%d/%Y') conversation_completed, 
                                                            ci.embargo_until embargo_until, ci.expiration_date expiration_date, 
                                                            ci.async_activity_id, aast.name async_activity_status_name, 
                                                            crt.code conversation_result_code, crt.name conversation_result_name,
                                                            date_format(aa.handled_on, '%H:%i:%S %m/%d/%Y') async_activity_handled_on", 
                                                :joins =>  "ci inner join conversation_result_type crt on ci.result_type_id = crt.id
                                                            inner join agent a on ci.agent_id = a.id
                                                            inner join sam_server ss on ss.id = a.sam_server_id
                                                            inner join sam_customer sc on sc.id = ss.sam_customer_id
                                                            inner join org o on o.id = sc.root_org_id
                                                            inner join customer c on c.id = o.customer_id
                                                            left join async_activity aa on (aa.id = ci.async_activity_id)
                                                            left join async_activity_status_type aast on aast.id = aa.status_id",
                                                :conditions => my_conditions, 
                                                :order => "sc.name ASC, ss.name ASC, ci.created_at ASC");

    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["UCN", "Customer Name", "SAM Server ID", "SAM Server Name", "Agent ID", "Conv. ID", "Result", "Create Date", "Start Date", "Complete Date", "Embargo Util", "Expiration Date", "Async Activity ID", "Async Activity Status Name", "Async Activity Handled On"]      
      @conv_data_list.each do |row|
        # data row
        csv_row << [row.ucn, row.cust_name, row.sam_server_id, row.sam_server_name, row.agent_id, row.conversation_instance_id, row.conversation_result_name, row.conversation_create_date, row.conversation_start_date, row.conversation_completed, row.embargo_until, row.expiration_date, row.async_activity_id, row.async_activity_status_name, row.async_activity_handled_on]                
      end
    end
    file_name = "conv_export_sub_batches.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
  end 


  def show_customers
    @conv_export_sub_batch = ConvExportSubBatch.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @conv_export_sub_batch }
    end
  end


  # GET /conv_export_sub_batches/new
  # GET /conv_export_sub_batches/new.xml
  def new
    @conv_export_sub_batch = ConvExportSubBatch.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @conv_export_sub_batch }
    end
  end

  # GET /conv_export_sub_batches/1/edit
  def edit
    @conv_export_sub_batch = ConvExportSubBatch.find(params[:id])
  end

  # POST /conv_export_sub_batches
  # POST /conv_export_sub_batches.xml
  def create
    @conv_export_sub_batch = ConvExportSubBatch.new(params[:conv_export_sub_batch])

    respond_to do |format|
      if @conv_export_sub_batch.save
        flash[:notice] = 'ConvExportSubBatch was successfully created.'
        format.html { redirect_to(@conv_export_sub_batch) }
        format.xml  { render :xml => @conv_export_sub_batch, :status => :created, :location => @conv_export_sub_batch }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @conv_export_sub_batch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /conv_export_sub_batches/1
  # PUT /conv_export_sub_batches/1.xml
  def update
    @conv_export_sub_batch = ConvExportSubBatch.find(params[:id])

    respond_to do |format|
      if @conv_export_sub_batch.update_attributes(params[:conv_export_sub_batch])
        flash[:notice] = 'ConvExportSubBatch was successfully updated.'
        format.html { redirect_to(@conv_export_sub_batch) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @conv_export_sub_batch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /conv_export_sub_batches/1
  # DELETE /conv_export_sub_batches/1.xml
  def destroy
    @conv_export_sub_batch = ConvExportSubBatch.find(params[:id])
    @conv_export_sub_batch.destroy

    respond_to do |format|
      format.html { redirect_to(conv_export_sub_batches_url) }
      format.xml  { head :ok }
    end
  end
end
