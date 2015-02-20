# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  before_filter {|c| ActiveRecord::SessionStore.session_class = Session}

  # no longer calling get_favorites; don't believe it's needed here but can be added back if there's an issue - MOD
  before_filter :login_required, :get_state_province, :get_terms, :get_dock_statuses, :except => [:login, :tms, :reset_password, :password_reset_response]
  before_filter :initialize_default_vars
  
  def paginate_by_sql(model, sql, per_page, options={})
       if options[:count]
           if options[:count].is_a? Integer
               total = options[:count]
           else
               total = model.count_by_sql(options[:count])
           end
       else
           total = model.count_by_sql_wrapping_select_query(sql)
       end

       object_pages = Paginator.new self, total, per_page,
            params['page']
       objects = model.find_by_sql_with_limit(sql,
            object_pages.current.to_sql[1], per_page)
       return [object_pages, objects]
   end
   
   
  def process_percent_complete(process_id, processor_code, phase)
    percent_complete = 0
    if (processor_code == "INIT")
      logger.info("inside the magic method")
      percent_complete = SamcProcess.find(process_id).pct_complete
    else
      complete_count = ProcessMessageResponse.count_by_token_code_phase(process_id, params[:processorcode], params[:phase], true)
      total_count = ProcessMessageResponse.count_total_by_token_code_phase(process_id, params[:processorcode], params[:phase])
      percent_complete = ((complete_count.to_f / total_count.to_f) * 100).to_i
    end
  ensure
    return percent_complete
  end
  
  def initialize_default_vars
    @widget_list = []
    @table_support = false
    @scrolling_support = false
    @progress_bar_support = false
    @date_selector_support = false
    @crappy_modal_support = false
    @chart_support = false
    @button_support = false
    @thickbox_support = false
    @initial_focus = true
    @prototype_required = false
  end
  
  
  def update_percentage
    percent_complete = process_percent_complete(params[:processid].to_i, params[:processorcode], params[:phase])
    render(:text => "#{params[:elementid]},#{percent_complete},#{params[:processid]},#{params[:processorcode]},#{params[:phase]}")
  end
  
  def monitor_process
    @process = SamcProcess.find(params[:processid].to_i)
    @complete = !@process.completed_at.nil?
    @process_code = params[:process_code]
    @process_threads = ProcessMessageResponse.find_incomplete_by_group(params[:processid].to_i)
    @status_msg_element = params[:status_msg_element]
    @thread_table_element = params[:thread_table_element]
  end
   
  
  private
  
  def get_dock_statuses
    @num_docked = 0
    if (session[:tasks_dock_status].nil?)
      tasks_dock = DockSetting.find(:first, :conditions => ["user_id = ? and dock_code = 'T'", current_user.id])
      if (!tasks_dock.nil? && tasks_dock.status == 1)
        session[:tasks_dock_status] = 1
      else
        session[:tasks_dock_status] = 0
      end
    end
    if (session[:sam_customers_dock_status].nil?)
      sam_customers_dock = DockSetting.find(:first, :conditions => ["user_id = ? and dock_code = 'SC'", current_user.id])
      if (!sam_customers_dock.nil? && sam_customers_dock.status == 1)
        session[:sam_customers_dock_status] = 1
      else
        session[:sam_customers_dock_status] = 0
      end
    end
    @num_docked += 1 if session[:tasks_dock_status] == 1
    @num_docked += 1 if session[:sam_customers_dock_status] == 1
  end
  
  def get_task_counts
    @controller_name = params[:controller]
    @action_name = params[:action]
    @my_task_count = Task.count(:conditions => ["current_user_id = ?", current_user.id])
    #@alerts = Alert.find(:all, :conditions => "user_type is not null", :order => "description")
    task_count_set = Task.all_counts(current_user)
    
    if( !task_count_set.empty? )
	    @task_counts = {}
	    @task_codes = {}
	    task_count_set.each do |tc|
		  @task_counts[tc.code] = TaskCounts.new(tc.description, tc.user_type) if @task_counts[tc.code].nil?
	      if (tc.status == Task.ASSIGNED)
	        @task_counts[tc.code].assigned = tc.task_count
	      elsif (tc.status == Task.UNASSIGNED)
	        @task_counts[tc.code].unassigned = tc.task_count
	      end
	    end
	    
	    # If no tasks exist of any one of 
	    #
	    #    Pending License Count Changes
        #    License Count Discrepancies 
	    #    SC-Licensing Activations
        #    License Count Integrity Problems
        #
        # populate with counts of zero for assigned & unassigned tasks.
	    TASK_CONTROLLER_LIST.each do |code|
	        # Omit Pending Entitlements and Super Admin Requests
	        if( @task_counts[code[0]].nil? && code[0] != 'UE' && code[0] != 'NSA' )
	            @task_counts[code[0]] = TaskCounts.new(code[2], 's')
	            @task_counts[code[0]].assigned = 0
	            @task_counts[code[0]].unassigned = 0
	        end
	    end
	        
	end
  end
  
  def get_terms
    if (current_user.isAdminType)
      @server_link = "SAM Servers and Agents"
      @community_info_term = "Community"
      @subcommunity_term = "Subcommunity"
    else
      @server_link = "SAM Servers"
      @community_info_term = "Product Class"
      @subcommunity_term = "Product"
    end
  end
  
  def get_state_province
    @state = StateProvince.find(session[:state_id]) if session[:state_id] 
  end
  
  def set_onload_string
     #puts "params: #{params.to_yaml}"
     @onload = "document.getElementById('#{params[:action]}').style.background = 'url(/images/tabonbg_sidebar.gif)';;"
  end
  
  def get_favorites
    @favorite_sam_customers = @current_user.favorite_sam_customer_set
  end
  
end

class TaskCounts
  attr_accessor :task_type_description, :assigned, :unassigned, :user_type
  
  def initialize(description, user_type)
    @task_type_description = description
    @assigned = 0
    @unassigned = 0
	@user_type = user_type
  end
  
end

class Widget
  
  attr_accessor :element_id, :title, :position, :height, :width
  
  def initialize(element_id, title, position, height, width)
    @element_id = element_id
    @title = title
    @position = position
    @height = height
    @width = width
  end
end

module ActiveRecord
    class Base
        def self.find_by_sql_with_limit(sql, offset, limit)
            sql = sanitize_sql(sql)
            add_limit!(sql, {:limit => limit, :offset => offset})
            find_by_sql(sql)
        end

        def self.count_by_sql_wrapping_select_query(sql)
            sql = sanitize_sql(sql)
            count_by_sql("select count(*) from (#{sql}) as my_table")
        end
   end
end
