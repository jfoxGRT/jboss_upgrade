require 'java'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end
class SaplingsController < ApplicationController

begin
  require 'fileutils'
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'hpricot'
rescue Exception => e
  p "WARNING: requires not found #{e}"
end

before_filter :get_current_user, :support_prototype

layout 'default_with_saplings_subtabs'

def authorized?
  return current_user.isAdminType || current_user.hasPermission?(Permission.manage_saplings)
end

def index
  redirect_to :controller => :saplings, :action => :index_repository
end

def index_repository
  #@saplings = Sapling.paginate(:page => params[:page], :select => "sapling.*", :per_page => PAGINATION_ROWS_PER_PAGE, 
  #                             :conditions => "state != 'i' AND fake = '0'", :order => "created_at desc")
  @saplings = Sapling.find(:all, :conditions => ["state != 'i'"], :order => "created_at desc")
end

def index_upload
end

def index_batch_targeting
end

def index_custom_targeting
  @products = Product.find(:all)
end

def custom_targeting_for_component
  @sapling = Sapling.find(params[:id])
  @minimum_version = SaplingMeta.find(:first, :conditions => ["sapling_id = ? and name = 'fromVersion'", params[:id]])
end

def target_sapling
  logger.debug "In target_sapling"
  @sapling = Sapling.find(params[:id])
  @sapling_target = []
  @sapling_target = SaplingTargeting.find(:all, :select => "st.*, ss.sam_customer_id as samc_id_from_server",
                                          :joins => "st inner join sam_server ss on st.sam_server_id = ss.id",
                                          :conditions => ["sapling_id = ?", params[:id]])
end

# DEPRECATED
#def refresh_eligibility
  #message_sender = SC.getBean("messageSender")
  #message_sender.sendServerEligibleUpdateMessage(nil, nil)
#  logger.info "Triggering global eligibility refresh"
  
#  msg_text = "{\"clazz\":\"sami.scholastic.messaging.message.ServerEligibleUpdateMessage\","
#  msg_text += ("\"timestamp\":" + Time.now.to_i.to_s + ",")
#  msg_text += "\"messageEventType\":\"NEW\","
#  msg_text += "\"global\":true,"
#  msg_text += "\"sourceComponentCode\":\"CUSTSERV-WEB\","
#  msg_text += "\"messageToken\":\"NONE\"}"
#  SamCentralMessage.create(:message => msg_text)
#  redirect_to :controller => :saplings, :action => :index_dashboard
#end


# Publish/Unpublish sapling
def publish_sapling
  @sapling = Sapling.find(params[:id])
  begin
    Sapling.transaction do
      if(@sapling.state != 'p')
        @sapling.state = 'p'
      else
        @sapling.state = 'a'
      end
      @sapling.published_at = Time.now
      @sapling.save!
    end
  rescue
    flash[:notice] = "The state of the sapling could not be changed.  Please try again."
  end
  redirect_to :controller => :saplings, :action => :edit, :id => params[:id]
end

def select_customer
  render(:layout => "popup_layout")
end

def select_server
  render(:layout => "popup_layout")
end

def select_product
  @products = Product.find(:all)
  @products.each do |product|
    logger.info "#{product.description}"
  end
  render(:layout => "popup_layout")
end

def show
  @sapling = params[:sapling_id] if params[:sapling_id]
end

def new
  @sapling = Sapling.new
  @sapling_meta_data = nil
  #@mode = "Add"
  render(:template => "saplings/add_sapling_form")
end

def create
  
  # in case the submission is unsuccessful, we want to return to the form with
  # all the information populated again, so we create the @sapling instance variable
  
  #@mode = "Add"
  @sapling = Sapling.new( params[:sapling] )
  
  @sapling.state = 'a'
  # set the state to published if necessary
  #if(params[:sapling][:scheduled] == "1")
    #@sapling.state = 'p' 
    #@sapling.published_at = Time.now
    #@sapling.scheduled = true
  #end
  @sapling_meta_data = []
  
  clean_dir("/var/samcentral/tmp")
  create_temp_file(@sapling, "/var/samcentral/tmp", "temp_file.zip")
  unzip_sapling_file("/var/samcentral/tmp/temp_file.zip", "/var/samcentral/tmp")
  parse_sapling_meta_with_hpricot("/var/samcentral/tmp/.meta.xml")
  
  logger.info "sapling id: #{@sapling.id}"
  logger.info "sapling code: #{@sapling.sapling_code}"
  logger.info "sapling version: #{@sapling.version}"
  logger.info "sapling type: #{@sapling.sapling_type}"
  logger.info "sapling os-family: #{@sapling.os_family}"
  logger.info "sapling os-series: #{@sapling.os_series}"
  logger.info "sapling cpu-type: #{@sapling.cpu_type}"
  logger.info "sapling cpu-bits: #{@sapling.cpu_bits}"
  
  #Make temp copies in case the form validation fails
  # Commenting out the remaining section for testing purpose
  
  #(params[:sapling_meta].each_pair {|key,value| @sapling_meta_data << SaplingMeta.new(:name => key, :value => value)}) if (!params[:sapling_meta].nil?)
  
  (render(:template => "saplings/add_sapling_form") and return) if (!@sapling.valid?)

  begin
    Sapling.transaction do
      @sapling.save!
      
      @sapling_meta_data.each do |smd|
        smd.sapling = @sapling
        smd.save!
      end
    move_sapling_file("/var/samcentral/tmp/temp_file.zip", "/var/samcentral/sapling_repository/#{@sapling.id}.zip")
      #create_sapling_file(@sapling, "/var/samcentral/sapling_repository")
      flash[:notice] = "Sapling added successfully"
    end
  rescue
    flash[:notice] = "Your request could not be processed.  Please try again."
  end
  
  FileUtils.rm_rf("/var/samcentral/tmp")
  redirect_to(:action => :index)
  
end

def edit
  @sapling = Sapling.find(params[:id])
  #@sapling.new_sapling_file = 0
  #@mode = "Update"
  @sapling_meta_data = SaplingMeta.find_all_by_sapling_id(params[:id])
  @minimum_sam_version = SaplingMeta.find(:first, :conditions => ["sapling_id = ? and name = 'minimumSamVersion'", params[:id]])
  @maximum_sam_version = SaplingMeta.find(:first, :conditions => ["sapling_id = ? and name = 'maximumSamVersion'", params[:id]])
  @local_or_hosted_deploy = SaplingMeta.find(:first, :conditions => ["sapling_id = ? and name = 'local_or_hosted_deploy'", params[:id]])
                                          
  @distributionScope = SaplingMeta.find(:first, :conditions => ["sapling_id = ? and name = 'distributionScope'", params[:id]])
                                                                                  
  @quizType = SaplingMeta.find(:first,
                                :conditions => ["sapling_id = ? and name = 'quizType'", params[:id]])
                                  
  @IS_IA_SAPLING = SaplingMeta.find(:first,
                                    :conditions => ["sapling_id = ? and name = 'IS_IA_SAPLING'", params[:id]])

  render(:template => "saplings/edit_sapling_form")
end

def update
 #@mode = "Update"
  @sapling = Sapling.find(params[:sapling][:id])
  @sapling.attributes = (params[:sapling])
  
  # set the state to published if necessary
  #if(params[:sapling][:scheduled] == "1")
  #  @sapling.state = 'p' 
  #  @sapling.published_at = Time.now
  #  @sapling.scheduled = true
  #end
  logger.info "@sapling: #{@sapling.to_yaml}"
  #logger.info "params sapling targeting: #{params[:sapling_targeting_hidden]}"
  logger.info "Update Sapling params: #{params.to_yaml}"
  
  begin
    Sapling.transaction do
    
    @update_targeting = '0';
    if(!params[:sapling_target].nil?)
      logger.info "SAPLING TARGET IS NOT NULL"
      params[:sapling_target].each_pair do |key, value|
      if(key == "update_targeting")
        @update_targeting = value
      logger.info "setting update_targeting to #{value}"
      end
    end
    end
    
    logger.info "update targeting is: #{@update_targeting}"
    
    if(@update_targeting == '0')
        # destroy all the existing meta data and create new objects for them
        # ignore minimumSamVersion, that's handled separated
        @current_sapling_meta = SaplingMeta.find_all_by_sapling_id(@sapling.id)
        
        SaplingMeta.destroy_all(["sapling_id = ? and name != 'minimumSamVersion' and name != 'minimumSamVersion'", params[:sapling][:id]])
        @sapling_meta_data = []
        
        temp_meta = []

        #STEP 1: put our params in. don't allow duplicates.
        params[:sapling_meta].each_pair do |key,value|
          if(value and !value.strip.empty?)
            new = true
            
            temp_meta.each do |tm|
              if(key == tm.name)
                new = false
                break
              end
            end
            
            if(new)
              temp_meta << SaplingMeta.new(:name => key, :value => value)
            end
          end
        end
        
        #STEP 2: save the param meta pairs
        logger.info "@sapling_meta_data: #{@sapling_meta_data.to_yaml}"      
        temp_meta.each do |smd|
          if(smd.name != "minimumSamVersion" and smd.name != "maximumSamVersion") # ignoring saving minimumSamVersion/maximumSamVersion, that's handled separately
            logger.info "saving sapling_meta named " + smd.name + "..."
            
            smd.sapling = @sapling
            smd.save!
          end
        end
      
        
        #STEP 3: re-add our existing saves ones if they're not included in the params. don't allow duplicates.
        @current_sapling_meta.each do |sapling_meta|
          if(sapling_meta.value and !sapling_meta.value.strip.empty?)
            new = true
            
            params[:sapling_meta].each_pair do |key,value|
              if(sapling_meta.name == key)
                new = false
                break
              end
            end
            
            if(new)
              record_to_save = SaplingMeta.new
              record_to_save.sapling_id=sapling_meta.sapling.id
              record_to_save.name=sapling_meta.name
              record_to_save.value=sapling_meta.value
              record_to_save.save
            end
          end
        end
            
        @sapling_meta_data = temp_meta | @current_sapling_meta
    end

    
    if(@update_targeting == '1')
      # destroy all the existing targeting data for sapling and create new objects for them
      logger.info "about to destroy targeting for sapling id: #{@sapling.id}"
      SaplingTargeting.destroy_all("sapling_id=#{@sapling.id}")
      logger.info "successfully destroyed"
      # adds sapling targeting data to array
      # the value of each param contains the id and the white list value
      @sapling_targeting_data = []
      if(!params[:sapling_targeting_hidden].nil?)
          params[:sapling_targeting_hidden].each_pair do |key,value| 
          #logger.info "key: #{key}, value: #{value}"
          if (key.split('.').first == "sam_customer_id") 
            id = value.split('.').first
            white_list = value.split('.').last
            @sapling_targeting_data << SaplingTargeting.new(:sam_customer_id => id, :white_list => white_list) 
          end
          if (key.split('.').first == "sam_server_id")
            id = value.split('.').first
            white_list = value.split('.').last
            @sapling_targeting_data << SaplingTargeting.new(:sam_server_id => id, :white_list => white_list)
          end 
          if (key.split('.').first == "product_id")
            id = value.split('.').first
            white_list = value.split('.').last        
            @sapling_targeting_data << SaplingTargeting.new(:product_id => id, :white_list => white_list)
          end
            if (key.split('.').first == "global")
              white_list = value.split('.').last
              @sapling_targeting_data << SaplingTargeting.new(:white_list => white_list)
            end 
          end
      end
    
      if(!@sapling_targeting_data.nil?)
        @sapling_targeting_data.each do |std|
        std.sapling = @sapling
        std.save!
        end
      end
    end
      
      ###########################################################################
      # Block for handling SAM min/max version meta
      # Note: these two meta data are not displayed along with regular meta data
      ###########################################################################
      @minimum_sam_version = params[:minimum_sam_version]
      @maximum_sam_version = params[:maximum_sam_version]
      if(@minimum_sam_version != "")
        logger.info "MINIMUM SAM VERSION: #{@minimum_sam_version}"
      else
        logger.info "MINIMUM SAM VERSION DOES NOT EXIST"
      end
      if(@maximum_sam_version != "")
        logger.info "MAXIMUM SAM VERSION: #{@maximum_sam_version}"
      else
        logger.info "MAXIMUM SAM VERSION DOES NOT EXIST"
      end
      
      @minimum_sam_version_meta = SaplingMeta.find(:first,
                                                   :conditions => ["sapling_id = ? and name = 'minimumSamVersion'", params[:id]])
      begin
        SaplingMeta.transaction do
          if(@minimum_sam_version != "" and @minimum_sam_version_meta == nil)
            logger.info "minimumSamVersion meta does not currently exist, create it"
            @minimum_sam_version_meta = SaplingMeta.new
            @minimum_sam_version_meta.sapling_id = params[:id]
            @minimum_sam_version_meta.name = "minimumSamVersion"
            @minimum_sam_version_meta.value = params[:minimum_sam_version]
            @minimum_sam_version_meta.save!
          elsif(@minimum_sam_version != "" and @minimum_sam_version_meta != nil)
            logger.info "minimumSamVersion meta currently exists, update it"
            @minimum_sam_version_meta.value = params[:minimum_sam_version]
            @minimum_sam_version_meta.save!
          elsif(@minimum_sam_version == "" and @minimum_sam_version_meta != nil)
            logger.info "minimumSamVersion meta exists and value is wiped out, destroy it"
            @minimum_sam_version_meta.destroy()
          end
        end
      rescue
        flash[:notice] = "Unable to save minimumSamVersion for sapling ID: #{params[:id]}"
      end
      
      @maximam_sam_version_meta = SaplingMeta.find(:first,
                                                   :conditions => ["sapling_id =? and name = 'maximumSamVersion'", params[:id]])
      begin
        SaplingMeta.transaction do
          if(@maximum_sam_version != "" and @maximum_sam_version_meta == nil)
            logger.info "maximumSamVersion meta does not currently exist, create it"
            @maximum_sam_version_meta = SaplingMeta.new
            @maximum_sam_version_meta.sapling_id = params[:id]
            @maximum_sam_version_meta.name = "maximumSamVersion"
            @maximum_sam_version_meta.value = params[:maximum_sam_version]
            @maximum_sam_version_meta.save!
          elsif(@maximum_sam_version != "" and @maximum_sam_version_meta != nil)
            logger.info "maximumSamVersion meta currently exists, update it"
            @maximum_sam_version_meta.value = params[:maximum_sam_version]
            @maximum_sam_version_meta.save!
          elsif(@maximum_sam_version == "" and @maximum_sam_version_meta != nil)
            logger.info "maximumSamVersion meta exists and value is wiped out, destroy it"
            @maximum_sam_version_meta.destroy()
          end
        end
      rescue
        flash[:notice] = "Unable to save maximumSamVersion for sapling ID: #{params[:id]}"
      end
      ###########################################################################
      # End of handling SAM min/max meta
      ###########################################################################
    
      if (!@sapling.valid?)
        render(:template => "saplings/edit_sapling_form")
        return
      end
    
    @sapling.updated_at = Time.now
      @sapling.save!
      
      create_sapling_file(@sapling, "/var/samcentral/sapling_repository") if @sapling.update_sapling_file == "1"
      flash[:notice] = "Sapling updated successfully."
      flash[:msg_info] = "info"
    end
  rescue
    flash[:notice] = "Your request could not be processed.  Please try again."
  end
    redirect_to(:action => :index_repository)
end

def show
  logger.info "params: #{params.to_yaml}"
  @sapling = Sapling.find(params[:id]) if params[:id]
  @sapling_meta_data = SaplingMeta.find(:all, :conditions => ["sapling_id = ?", params[:id]])
  render(:layout => "cs_blank_layout")
end

def destroy
   @sapling = Sapling.find(params[:id])
   @sapling.state = 'i'
   @sapling.save!
   flash[:notice] = "Deleted sapling successfully"
   redirect_to(:action => :index_repository)
end


#################
# AJAX ROUTINES #
#################

# This retrieves a list of customers using the query specified by user
def retrieve_list_by_query 
  query_type = params[:query_type]
  logger.info "PARAMS: #{params.to_yaml}"
  if(query_type == "sam_customer sc")
  custom_query = params[:custom_query]
  sql = <<EOS
    SELECT DISTINCT sc.id as sam_customer_id, sc.name as sam_customer_name
    FROM 
      sam_customer sc #{custom_query}
EOS
  @result = SamCustomer.find_by_sql(sql)
  @result.each do |row|
    logger.info "name: #{row.sam_customer_name}, id: #{row.sam_customer_id}"
  end
  render(:update) { |page|
    page.replace_html "batch_targeting_body", render(:partial => "customer_table_by_query", :layout => false)
  }
   
 elsif (query_type == "sam_server ss")
  custom_query = params[:custom_query]
  sql = <<EOS
    SELECT DISTINCT ss.id as sam_server_id, ss.name as sam_server_name
    FROM 
      sam_server ss #{custom_query}
EOS
  @result = SamServer.find_by_sql(sql)
  @result.each do |row|
    logger.info "name: #{row.sam_server_name}, id: #{row.sam_server_id}"
end
  render(:update) { |page|
    page.replace_html "batch_targeting_body", render(:partial => "server_table_by_query", :layout => false)
      
  }
   
  end
end

# This retrieves a list of customers using the UI form
def retrieve_customer_list_by_form
  logger.info "PARAMS: #{params.to_yaml}"
  with_entitlement = params[:entitlement_checkbox]
  with_fake_customers = params[:include_fake_checkbox]
  with_um_activated = params[:um_activated_checkbox]
  with_update_components_as_avail = params[:update_components_as_avail_checkbox]
  with_update_quiz_as_avail = params[:update_quiz_as_avail_checkbox]
  entitlement_product_id = ""
  entitlement_date = ""
  if(with_entitlement)
    entitlement_date = params[:entitlement_date]
    logger.debug "entitlement date: #{entitlement_date}"
    entitlement = params[:entitlement_select]
    entitlement.map do |key, value|
      entitlement_product_id = value
      logger.info "entitlement product id: #{entitlement_product_id}"
    end
  end
  customer_type = params[:customer_type]
  um_actived_clause = ""
  if(with_um_activated)
    um_activated_clause = "and sc.update_manager_activated is not null"
  end
  update_components_clause = ""
  if(with_update_components_as_avail) 
    update_components_clause = "and sc.update_as_available = 1"
  end
  update_quizzes_clause = ""
  if(with_update_quiz_as_avail) 
    update_quizzes_clause = "and sc.update_quiz_as_available = 1"
  end
  fake_customer_clause = ""
  if(with_fake_customers)
    fake_customer_clause = "and (sc.fake = 1 or sc.fake = 0)"
  else
    fake_customer_clause = "and sc.fake = 0"
  end
  customer_clause = ""
  if(customer_type == "hosted") # Hosted-only customer ids
    hosted_only_customer_id_list = get_hosted_only_customer_id_list()
    if(hosted_only_customer_id_list != "")
      customer_clause = " and sc.id in (#{hosted_only_customer_id_list})"
    else
      customer_clause = " and sc.id in (0)"
    end
  elsif(customer_type == "hybrid") # Hybrid customer ids
    hybrid_customer_id_list = get_hybrid_customer_id_list()
    if(hybrid_customer_id_list != "")
      customer_clause = " and sc.id in (#{hybrid_customer_id_list})"
    else
      customer_clause = " and sc.id in (0)"
    end
  elsif(customer_type == "regular")
    regular_customer_id_list = get_regular_customer_id_list()
    if(regular_customer_id_list != "")
      customer_clause = " and sc.id in (#{regular_customer_id_list})"
    else
      customer_clause = " and sc.id in (0)"
    end
  end
  if(with_entitlement)
    sc_customer_sql = <<EOS 
      select distinct sc.name as sam_customer_name, sc.id as sam_customer_id from sam_customer sc, product p, entitlement e where e.sam_customer_id = sc.id and e.product_id = p.id and p.id_value = #{entitlement_product_id} and '#{entitlement_date}' > e.subscription_start and ('#{entitlement_date}' < e.subscription_end or e.subscription_end is null) and e.subscription_start is not null and sc.active = 1
        #{um_activated_clause}
        #{update_components_clause}
        #{update_quizzes_clause}
        #{fake_customer_clause}
        #{customer_clause}
      order by sam_customer_id
EOS
  else
    sc_customer_sql = <<EOS
      select distinct 
        sc.name as sam_customer_name, sc.id as sam_customer_id
      from
        sam_customer sc
      where
        sc.active = 1
        #{um_activated_clause}
        #{update_components_clause}
        #{update_quizzes_clause}
        #{fake_customer_clause}
        #{customer_clause}
      order by sam_customer_id
EOS
  end
  logger.info "SQL: #{sc_customer_sql}"
  @result = SamCustomer.find_by_sql(sc_customer_sql)
  
  render(:update) { |page|
    page.replace_html "custom_targeting_body", render(:partial => "customer_table_by_form", :layout => false)
  }
end

# This retrieves a list of servers using the UI form
def retrieve_server_list_by_form
  logger.info "PARAMS: #{params.to_yaml}"
  with_fake_customers = params[:include_fake_checkbox]
  fake_customer_clause = ""
  if(with_fake_customers)
    fake_customer_clause = "(sc.fake = 1 or sc.fake = 0)"
  else
    fake_customer_clause = "sc.fake = 0"
  end
  os_family_clause = ""
  os_family = params[:os_family]
  if (os_family == "WINDOWS")
    os_family_clause = " a.os_family = 'WINDOWS' and "
  elsif (os_family == "OSX")
    os_family_clause = " a.os_family = 'OSX' and "
  elsif (os_family == "LINUX")
    os_family_clause = " a.os_family = 'LINUX' and "
  end
  min_component_clause = ""
  if (params[:min_component_version] != nil && params[:min_component_version] != "")
    min_component_clause = " ac.value >= " + params[:min_component_version] + " and "
  end
  component_name_clause = " lower(ac.name) = '" + params[:sapling_code] + "' and "
  max_component_clause = " ac.value < " + params[:sapling_version] + " and "

    custom_sql = <<EOS
      select distinct 
        ss.name as sam_server_name, ss.id as sam_server_id
      from 
        sam_customer sc, sam_server ss, agent a, agent_component ac 
      where 
        ss.sam_customer_id = sc.id and
        a.sam_server_id = ss.id and
        ac.agent_id = a.id and 
        ss.status = 'a' and 
        ss.server_type = 0 and 
        sc.active = 1 and
        #{os_family_clause}
        #{component_name_clause}
        #{min_component_clause}
        #{max_component_clause}
        #{fake_customer_clause}
EOS
  logger.info "SQL: #{custom_sql}"
  @result = SamServer.find_by_sql(custom_sql)
  @sapling_id = params[:sapling_id]
  
  render(:update) { |page|
    page.replace_html "custom_targeting_body", render(:partial => "server_table_by_form", :layout => false)
  }
end

# Returns comma separated ids for hosted-only customers
def get_hosted_only_customer_id_list
  # SQL that finds customers that have one or more hosted servers
  hosted_only_customer_id_list = ""
  sc_customer_with_hosted_server_sql = <<EOS
    select distinct
      sc.id sam_customer_id
    from 
      sam_customer sc, sam_server ss
    where 
      ss.sam_customer_id = sc.id and
      sc.active = 1 and 
      ss.status in ('a','t') and
      ss.server_type = 1
EOS
  customers_with_hosted_server = SamCustomer.find_by_sql(sc_customer_with_hosted_server_sql)
  customers_with_hosted_server.each do |customer|
    customer_id = customer.sam_customer_id
    # SQL that finds a list of active servers for a customer
    customer_servers_list_sql = <<EOS
      select *
      from
        sam_server ss
      where 
        ss.sam_customer_id = #{customer_id} and
        ss.status in ('a','t')
EOS
    customer_servers_list = SamServer.find_by_sql(customer_servers_list_sql)
    is_hosted_only = 1
    customer_servers_list.each do |server|
      logger.info "Processing server id: #{server.id}"
      if(server.server_type == 0)
        logger.info "For customer #{customer.sam_customer_id}, non-hosted server is found"
        is_hosted_only = 0
        break
      end
    end
    if(is_hosted_only == 1)
      logger.info "Customer ID: #{customer.sam_customer_id} is a Hosted-only customer"
      hosted_only_customer_id_list = hosted_only_customer_id_list + "#{customer.sam_customer_id},"
    end
  end
  hosted_only_customer_id_list = hosted_only_customer_id_list.chop # comma separated id list for hosted-only customers
  logger.info "hosted only customer id list: #{hosted_only_customer_id_list}"
  return hosted_only_customer_id_list
end

# Returns comma separated ids for hybrid customers
def get_hybrid_customer_id_list
  # SQL that finds customers that have one or more hosted servers
  hybrid_customer_id_list = ""
  sc_customer_with_hosted_server_sql = <<EOS
    select distinct
      sc.id sam_customer_id
    from 
      sam_customer sc, sam_server ss
    where 
      ss.sam_customer_id = sc.id and
      sc.active = 1 and 
      ss.status in ('a', 't') and
      ss.server_type = 1
EOS
  customers_with_hosted_server = SamCustomer.find_by_sql(sc_customer_with_hosted_server_sql)
  customers_with_hosted_server.each do |customer|
    customer_id = customer.sam_customer_id
    # SQL that finds a list of active servers for a customer
    customer_servers_list_sql = <<EOS
      select *
      from
        sam_server ss
      where 
        ss.sam_customer_id = #{customer_id} and
        ss.status = 'a'
EOS
    customer_servers_list = SamServer.find_by_sql(customer_servers_list_sql)
    is_hosted_only = 1
    customer_servers_list.each do |server|
      logger.info "Processing server id: #{server.id}"
      if(server.server_type == 0)
        logger.info "For customer #{customer.sam_customer_id}, non-hosted server is found"
        is_hosted_only = 0
        break
      end
    end
    if(is_hosted_only != 1)
      hybrid_customer_id_list = hybrid_customer_id_list + "#{customer.sam_customer_id},"
    end
  end
  hybrid_customer_id_list = hybrid_customer_id_list.chop # comma separated id list for hybrid customers
  logger.info "hybrid customer id list: #{hybrid_customer_id_list}"
  return hybrid_customer_id_list
end

# Returns comma separated ids for regular customers
def get_regular_customer_id_list
  # SQL that finds customers that have one or more regular servers
  regular_customer_id_list = ""
  sc_customer_with_regular_server_sql = <<EOS
    select distinct
      sc.id sam_customer_id
    from 
      sam_customer sc, sam_server ss
    where 
      ss.sam_customer_id = sc.id and
      sc.active = 1 and 
      ss.status in ('a', 't') and
      ss.server_type = 0
EOS
  customers_with_regular_server = SamCustomer.find_by_sql(sc_customer_with_regular_server_sql)
  customers_with_regular_server.each do |customer|
    customer_id = customer.sam_customer_id
    # SQL that finds a list of active servers for a customer
    customer_servers_list_sql = <<EOS
      select *
      from
        sam_server ss
      where 
        ss.sam_customer_id = #{customer_id} and
        ss.status in ('a', 't')
EOS
    customer_servers_list = SamServer.find_by_sql(customer_servers_list_sql)
    is_regular_only = 1
    customer_servers_list.each do |server|
      logger.info "Processing server id: #{server.id}"
      if(server.server_type == 1)
        logger.info "For customer #{customer.sam_customer_id}, hosted server is found"
        is_regular_only = 0
        break
      end
    end
    if(is_regular_only == 1)
      logger.info "Customer ID: #{customer.sam_customer_id} is a regular customer"
      regular_customer_id_list = regular_customer_id_list + "#{customer.sam_customer_id},"
    end
  end
  regular_customer_id_list = regular_customer_id_list.chop # comma separated id list for regular customers
  logger.info "regular customer id list: #{regular_customer_id_list}"
  return regular_customer_id_list
end

# This loops through the list of customers and inserts targeting rule for each customer selected
def insert_targeting_rules
  logger.info "PARAMS: #{params.to_yaml}"
  sapling_id_list = params[:sapling_id_list].split(',') # Splitting comma separated sapling ids
  check_boxes = params[:check_box]
  if(check_boxes != nil and sapling_id_list != nil)
    sapling_id_list.each do |sapling_id| # For each sapling id
      begin
        SaplingTargeting.transaction do
          check_boxes.map do |key, value| # For each customer selected
            logger.info "Customer ID: #{key} selected"
            targeting = SaplingTargeting.new
            targeting.sapling_id = sapling_id.to_i
            targeting.white_list = 1
            targeting.sam_customer_id = key.to_i
            targeting.save!
          end
        end
        flash[:save_successful] = "The targeting rules have been saved successfully"
      rescue Exception => e
        logger.info "ERROR: #{e}"
        flash[:save_unsuccessful] = "The targeting rules could not be saved successfully"
      end
    end
  else
    flash[:nothing_to_save] = "You have not selected anything to save. Please verify that the sapling ID is correct and customers are selected."
  end
  render(:update) { |page|
    page.replace_html "batch_targeting_body", render(:partial => "batch_targeting_complete", :layout => false)
  }
end


# This loops through the list of servers and inserts targeting rule for each server selected
def insert_serv_targeting_rules
  logger.info "PARAMS: #{params.to_yaml}"
  sapling_id_list = params[:sapling_id_list].split(',') # Splitting comma separated sapling ids
  check_boxes = params[:check_box]
  if(check_boxes != nil and sapling_id_list != nil)
    sapling_id_list.each do |sapling_id| # For each sapling id
      begin
        SaplingTargeting.transaction do
          check_boxes.map do |key, value| # For each customer selected
            logger.info "Server ID: #{key} selected"
            targeting = SaplingTargeting.new
            targeting.sapling_id = sapling_id.to_i
            targeting.white_list = 1
            targeting.sam_server_id = key.to_i
            targeting.save!
          end
        end
        flash[:save_successful] = "The targeting rules have been saved successfully"
      rescue Exception => e
        logger.info "ERROR: #{e}"
        flash[:save_unsuccessful] = "The targeting rules could not be saved successfully"
      end
    end
  else
    flash[:nothing_to_save] = "You have not selected anything to save. Please verify that the sapling ID is correct and servers are selected."
  end
  render(:update) { |page|
    page.replace_html "batch_targeting_body", render(:partial => "batch_targeting_complete", :layout => false)
  }
end

# This loops through the list of customers and inserts targeting rule for each customer selected
def insert_targeting_rules_by_form
  logger.info "PARAMS: #{params.to_yaml}"
  sapling_id_list = params[:sapling_id_list].split(',') # Splitting comma separated sapling ids
  check_boxes = params[:check_box]
  if(check_boxes != nil and sapling_id_list != nil)
    sapling_id_list.each do |sapling_id| # For each sapling id
      begin
        SaplingTargeting.transaction do
          check_boxes.map do |key, value| # For each customer selected
            logger.info "Customer ID: #{key} selected"
            targeting = SaplingTargeting.new
            targeting.sapling_id = sapling_id.to_i
            targeting.white_list = 1
            targeting.sam_customer_id = key.to_i
            targeting.save!
          end
        end
        flash[:save_successful] = "The targeting rules have been saved successfully"
      rescue Exception => e
        logger.info "ERROR: #{e}"
        flash[:save_unsuccessful] = "The targeting rules could not be saved successfully"
      end
    end
  else
    flash[:nothing_to_save] = "You have not selected anything to save. Please verify that the sapling ID is correct and customers are selected."
  end
  render(:update) { |page|
    page.replace_html "custom_targeting_body", render(:partial => "custom_targeting_complete", :layout => false)
  }
end

# This loops through the list of servers and inserts targeting rule for each server selected
def insert_server_targeting_rules
  logger.info "PARAMS: #{params.to_yaml}"
  sapling_id = params[:sapling_id]
  check_boxes = params[:check_box]
  if(check_boxes != nil and sapling_id != nil and sapling_id != '')
    begin
      SaplingTargeting.transaction do
        check_boxes.map do |key, value| # For each server selected
          logger.info "Server ID: #{key} selected"
          targeting = SaplingTargeting.new
          targeting.sapling_id = sapling_id.to_i
          targeting.white_list = 1
          targeting.sam_server_id = key.to_i
          targeting.save!
        end
      end
      flash[:save_successful] = "The targeting rules have been saved successfully"
    rescue Exception => e
      logger.info "ERROR: #{e}"
      flash[:save_unsuccessful] = "The targeting rules could not be saved successfully"
    end
  else
    flash[:nothing_to_save] = "You have not selected anything to save. Please verify that at least one server is selected."
  end
  render(:update) { |page|
    page.replace_html "custom_targeting_body", render(:partial => "custom_targeting_complete", :layout => false)
  }
end

def update_saplings_table
  logger.info "params: #{params.to_yaml}"
  if(params[:sort] != nil)
    logger.info "Sort param provided"
    @saplings = Sapling.paginate(:page => params[:page], :select => "sapling.*", :per_page => PAGINATION_ROWS_PER_PAGE, 
                                 :conditions => "state != 'i'", :order => saplings_sort_by_param(params["sort"]))
  else
    logger.info "No sort param provided"
    @saplings = Sapling.paginate(:page => params[:page], :select => "sapling.*", :per_page => PAGINATION_ROWS_PER_PAGE, 
                                 :conditions => "state != 'i'", :order => "created_at desc")    
  end
  render(:partial => "saplings_info", 
         :locals => {:saplings_collection => @saplings,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :current_user => current_user}, :layout => false)
end

def update_sapling_row
  @sapling = Sapling.find(params[:id])
  if(@sapling.state == 'p')
    @sapling.state = 'a'
  else
    @sapling.state = 'p'
    @sapling.published_at = Time.now
  end
  #@sapling.scheduled = true
  @sapling.save!
end

# Finds customer by a string in the name, same as sam_customers
def find_customer_by_name
  @sam_customers = SamCustomer.find_by_keystring(params[:key_string])
end

# Finds customer by a string in the name, same as sam_customers
def find_customer_by_name_for_servers
  @sam_customers = SamCustomer.find_by_keystring(params[:key_string])
end

def find_server_by_customer
  logger.info "customer id from params: #{params[:id]}"
  @servers = SamServer.find(:all, :conditions => ["sam_customer_id = ?", params[:id]])
end

private

# Creates a temp file for sapling zip
def create_temp_file(obj, dir, temp_file_name)
  logger.info "Creating temp file #{temp_file_name} in directory #{dir}"
  FileUtils.mkdir(dir) if !File.exists?(dir)
  FileUtils.cd(dir) do |dir|
    File.delete(temp_file_name) if File.exists?(temp_file_name)
    f = File.new(temp_file_name, "wb")
    str = ""
    str << obj.binary_data
    f.print(str)
    f.close
  end
end

def create_sapling_file(sapling_obj, sapling_dir)
  # Create directory if it doesn't exist
  FileUtils.mkdir(sapling_dir) if !File.exists?(sapling_dir)
  new_file_name = "#{sapling_obj.id}.zip"
  FileUtils.cd(sapling_dir) do |dir|
    File.delete(new_file_name) if File.exists?(new_file_name)
    f = File.new(new_file_name, "wb")
    str = ""
    str << sapling_obj.binary_data
    f.print(str)
    f.close
  end
end

# Copy the temp sapling file to sapling repository
def move_sapling_file(from_file, to_file)
  sapling_dir = "/var/samcentral/sapling_repository"
  FileUtils.mkdir(sapling_dir) if !File.exists?(sapling_dir)
  File.delete(to_file) if File.exists?(to_file)
  File.copy(from_file, to_file)
end

# Cleans a directory by deleting its content
def clean_dir(dir)
  if File.exists?(dir)
    logger.info "deleting tmp dir #{dir}"
    FileUtils.rm_rf(dir) # removes directory if exists
  end
  if !File.exists?(dir)
    logger.info "creating tmp dir #{dir}"
  FileUtils.mkdir(dir) # creates directory if doesn't exist
  end
end

# Unzips to a specific directory
def unzip_sapling_file(zip_file, destination)
  logger.info "Unzipping file #{zip_file}"
  Zip::ZipFile.open(zip_file).each do |single_file|
    file_path = File.join(destination, single_file.name)
  FileUtils.mkdir_p(File.dirname(file_path))
    single_file.extract(file_path)
  end
end

# Parses the .meta.xml file and sets the right sapling attributes
# This uses REXML to parse, causes error in tomcat
def parse_sapling_meta(xml_file)
  xml = File.read(xml_file)
  doc = REXML::Document.new(xml)
  sapling_element = doc.root
  @sapling.sapling_code = sapling_element.attribute("id").value
  @sapling.version = sapling_element.attribute("version").value
  version = sapling_element.attribute("version").value
  @sapling.sapling_type = sapling_element.attribute("type").value
  
  sapling_element.each_element("platform") do |platform_element|
    @sapling.os_family = platform_element.attribute("os-family").value
  @sapling.os_series = platform_element.attribute("os-series").value
  @sapling.cpu_bits = platform_element.attribute("cpu-bits").value
  @sapling.cpu_type = platform_element.attribute("cpu-type").value
  end
  
  sapling_element.each_element("meta") do |meta_element|
    key = meta_element.attribute("name").value
  value = meta_element.text
  logger.info "key: #{key}, value: #{value}"
    @sapling_meta_data << SaplingMeta.new(:name => key, :value => value)
  end
end

# Parses the .meta.xml file and sets the right sapling attributes
# This uses Hpricot to parse
def parse_sapling_meta_with_hpricot(xml_file)
  xml = File.read(xml_file)
  doc = Hpricot::XML(xml)
  sapling_element = doc.find_element("sapling")
  logger.info "Sapling element: #{sapling_element}"
  @sapling.sapling_code = sapling_element.get_attribute("id")
  logger.info "sapling code: #{@sapling.sapling_code}"
  @sapling.version = sapling_element.get_attribute("version")
  @sapling.sapling_type = sapling_element.get_attribute("type")
  platform_element = doc.find_element("platform")
  @sapling.os_series = platform_element.get_attribute("os-series")
  @sapling.os_family = platform_element.get_attribute("os-family")
  @sapling.cpu_bits = platform_element.get_attribute("cpu-bits")
  @sapling.cpu_type = platform_element.get_attribute("cpu-type")
  if(sapling_element.get_attribute("type") == "CONTENT")
    @sapling.marketing_name = sapling_element.get_attribute("marketingname")
  elsif(sapling_element.get_attribute("type") == "SAM_SERVER_COMPONENT")
    @sapling.marketing_name = sapling_element.get_attribute("marketingname")
    if @sapling.marketing_name
      osFamily = platform_element.get_attribute("os-family")
      if osFamily
        @sapling.marketing_name << (" (" + osFamily[0,1] + ")")
      end
    end
  end
  doc.get_elements_by_tag_name("meta").each do |meta_element|
  key = meta_element.get_attribute("name")
  value = meta_element.innerHTML
    logger.info "key: #{key}, value: #{value}"
  @sapling_meta_data << SaplingMeta.new(:name => key, :value => value)
  end
end

def saplings_sort_by_param(sort_by_arg)
  case sort_by_arg
    when "sapling_id" then "id"
    when "created_at" then "created_at"
    when "updated_at" then "updated_at"
    when "published_at" then "published_at"
    when "sapling_code" then "sapling_code"
    when "sapling_type" then "sapling_type"
    when "sapling_version" then "version"
    when "os_family" then "os_family"
    when "os_series" then "os_series"
    when "cpu_type" then "cpu_type"
    when "cpu_bits" then "cpu_bits"
    when "schedulable" then "scheduled"
    when "current_state" then "state"
    
    when "sapling_id_reverse" then "id desc"
    when "created_at_reverse" then "created_at desc"
    when "updated_at_reverse" then "updated_at desc"
    when "published_at_reverse" then "published_at desc"
    when "sapling_code_reverse" then "sapling_code desc"
    when "sapling_type_reverse" then "sapling_type desc"
    when "sapling_version_reverse" then "version desc"
    when "os_family_reverse" then "os_family desc"
    when "os_series_reverse" then "os_series desc"
    when "cpu_type_reverse" then "cpu_type desc"
    when "cpu_bits_reverse" then "cpu_bits desc"
    when "schedulable_reverse" then "scheduled desc"
    when "current_state_reverse" then "state desc"
  end
end

def support_prototype
  @prototype_required = true
  @thickbox_support = true
end

def get_current_user
  @current_user = current_user
end

end
