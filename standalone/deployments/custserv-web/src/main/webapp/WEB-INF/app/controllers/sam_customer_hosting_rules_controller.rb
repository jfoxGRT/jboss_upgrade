class SamCustomerHostingRulesController < SamCustomersController
  
  before_filter :load_hosting_rules, :set_breadcrumb, :load_required_js_libraries
  
  layout 'default'
  
  def index
      @sam_customer_id = params[:sam_customer_id].to_i
      @hosting_rules = HostingEnrollmentRuleDelivery.paginate(:all, :page => params[:page], :select =>
            "herd.*, ss.name as server_name, ss.id as server_id", :joins => "herd inner join sam_server ss on herd.target_sam_server_id = ss.id inner join sam_customer sc on ss.sam_customer_id = sc.id", :conditions => ["ss.sam_customer_id = ? and ss.status = 'a'", @sam_customer_id], :order => "herd.id desc", :per_page => PAGINATION_ROWS_PER_PAGE)
  end
  
  def update_hosting_rules
      @sam_customer_id = params[:sam_customer_id].to_i
      @hosting_rules = paginate_hosting_rules(params[:sam_customer_id], params[:page], params[:sort])
      render(:partial => "sam_customer_hosting_rules_table", :locals => {:hosting_rules_collection => @hosting_rules,
                                                                         :status_indicator => params[:status_indicator],
                                                                         :sam_customer_id => @sam_customer.id,
                                                                         :update_element => "sam_customer_hosting_rules_table"},
                                                             :layout => false)
  end
  
  def paginate_hosting_rules(sam_customer_id, params_page, params_sort)
      @hosting_rules = HostingEnrollmentRuleDelivery.paginate(:all, :page => params[:page], :select =>
            "herd.*, ss.name as server_name, ss.id as server_id", :joins => "herd inner join sam_server ss on herd.target_sam_server_id = ss.id inner join sam_customer sc on ss.sam_customer_id = sc.id", :conditions => ["ss.sam_customer_id = ? and ss.status = 'a'", @sam_customer_id], :order => hosting_rules_sort_by_param(params_sort), :per_page => PAGINATION_ROWS_PER_PAGE)
  end
  
  def hosting_rules_sort_by_param(sort_by_arg)
      case sort_by_arg
          when "hosting_rule_id" then "herd.id"
          when "hosting_rule_id_reverse" then "herd.id desc"
          when "server_name" then "ss.name"
          when "server_name_reverse" then "ss.name desc"
          when "server_id" then "ss.id"
          when "server_id_reverse" then "ss.id desc"
          when "entitlement_id" then "herd.source_entitlement_id"
          when "entitlement_id_reverse" then "herd.source_entitlement_id desc"
          when "status" then "herd.status"
          when "status_reverse" then "herd.status desc"
          when "created" then "herd.created"
          when "created_reverse" then "herd.created desc"
          when "delivered" then "herd.delivered"
          when "delivered_reverse" then "herd.delivered desc"
      end
  end
  
  def set_breadcrumb
      @site_area_code = HOSTING_RULES_CODE
  end
  
  def load_hosting_rules
      @hosting_rule = HostingEnrollmentRuleDelivery.find(params[:hosting_rule_id]) if params[:hosting_rule_id]
  end
  
  def load_required_js_libraries
      @prototype_required = true
  end
  
end