class CsiController < ApplicationController

  layout 'new_layout_with_jeff_stuff'

  def index
    redirect_to(:action => :org_hierarchy_states)
  end
  
  ###############
  # STATES PAGE #
  ###############
  
  def org_hierarchy_states
    usCountryId = Country.find_by_code("US").id
    @state_provinces = StateProvince.paginate(:page => params[:page], :select => "state_province.*, country.id as country_id, country.name as country_name",
                                              :joins => "inner join country on state_province.country_id = country.id",
                                              :conditions => ["country.id = ?", usCountryId],
                                              :order => states_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
    #if request.xml_http_request?
    #  render(:partial => "csi_state_province", :locals => {:state_province_collection => @state_provinces}, :layout => false)
    #end
  end
  
  
  
  #######################
  # TOP_LEVEL_ORGS PAGE #
  ####################### 
  
  def top_level_orgs
    (redirect_to(:action => :org_hierarchy_states) and return) if (params[:id].nil?)
    @state = StateProvince.find(params[:id])
    @stateTlos = Org.paginate(:page => params[:page], :select => "org.*",
                                            :joins => "inner join top_level_org on top_level_org.org_id = org.id \
                                                       inner join customer on org.customer_id = customer.id \
                                                       inner join customer_address on customer_address.customer_id = customer.id \
                                                       inner join state_province on customer_address.state_province_id = state_province.id \
                                                       inner join address_type on customer_address.address_type_id = address_type.id",
                                            :conditions => ["top_level_org.top_level_org_id = ? and state_province.id = ? and \
                                                             (address_type.code = '05' or address_type.code = '06')", Org.getInternalOrg.id, params[:id]],
                                            :per_page => PAGINATION_ROWS_PER_PAGE)
    #if(request.xml_http_request?)
    #  render(:partial => "org_info", :locals => {:state_tlo_collection => @stateTlos}, :layout => false)
    #end
  end
  
  
  
  ######################
  # ORG_HIERARCHY PAGE #
  ######################  
  
  def org_hierarchy
    (redirect_to(:action => :org_hierarchy_states) and return) if (params[:id].nil? || params[:state_id].nil?)
    @state = StateProvince.find(params[:state_id])    
    @org = Org.find(params[:id])
    @sup2sub = RelationshipCategory.find_by_code("01")    
    @orgList = Org.paginate(:page => params[:page], :select => "org.*",
                                        :joins => "inner join customer on org.customer_id = customer.id \
                                                   inner join customer_relationship on customer_relationship.customer_id = customer.id \
                                                   inner join relationship_category on relationship_category.id = customer_relationship.relationship_category_id",
                                        :conditions => ["customer_relationship.related_customer_id = ? and \
                                                         customer_relationship.effective <= ? and \
                                                         (customer_relationship.end is null or customer_relationship.end > ?) and \
                                                         customer_relationship.relationship_category_id = ?", @org.customer.id, Date.today.to_s, Date.today.to_s, @sup2sub.id],
                                        :order => org_hierarchy_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
    # Populate the breadcrumb array
    @breadcrumbArray = []
    @breadcrumbArray = formBreadcrumbArray(@org, @breadcrumbArray, 0).reverse
  end
  
  
  
  ###############################
  # ORG_HIERARCHY_BRACKETS PAGE #
  ###############################
  
  def org_hierarchy_brackets
  
    large_org_sql = "select top_level_org.*, count(*) as the_count from top_level_org where top_level_org_id != #{Org.getInternalOrg.id} \
              group by top_level_org_id having the_count > 10 order by the_count desc"
    @large_tops = TopLevelOrg.paginate_by_sql(large_org_sql, :page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    
    mid_org_sql = "select top_level_org.*, count(*) as the_count from top_level_org where top_level_org_id != #{Org.getInternalOrg.id} \
              group by top_level_org_id having the_count <= 10 and the_count > 3 order by the_count desc"
    @mid_tops = TopLevelOrg.paginate_by_sql(mid_org_sql, :page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    
    small_org_sql = "select top_level_org.*, count(*) as the_count from top_level_org where top_level_org_id != #{Org.getInternalOrg.id} \
              group by top_level_org_id having the_count <= 3 and the_count > 1 order by the_count desc"
    @small_tops = TopLevelOrg.paginate_by_sql(small_org_sql, :page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    
  end
  
  
  
  ###################
  # ORG_FINDER PAGE #
  ###################
  
  def org_finder
  end
  
  
  #################
  # AJAX ROUTINES #
  #################
  
  def update_org_hierarchy_states_table
    usCountryId = Country.find_by_code("US").id
    @state_provinces = StateProvince.paginate(:page => params[:page], :select => "state_province.*, country.id as country_id, country.name as country_name",
                                              :joins => "inner join country on state_province.country_id = country.id",
                                              :conditions => ["country.id = ?", usCountryId],
                                              :order => states_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "csi_state_province",
           :locals => {:state_province_collection => @state_provinces,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element]}, :layout => false)
  end
  
  def update_top_level_org_table
    @state = StateProvince.find(params[:id])
    @stateTlos = Org.paginate(:page => params[:page], :select => "org.*",
                                            :joins => "inner join top_level_org on top_level_org.org_id = org.id \
                                                       inner join customer on org.customer_id = customer.id \
                                                       inner join customer_address on customer_address.customer_id = customer.id \
                                                       inner join state_province on customer_address.state_province_id = state_province.id \
                                                       inner join address_type on customer_address.address_type_id = address_type.id",
                                            :conditions => ["top_level_org.top_level_org_id = ? and state_province.id = ? and \
                                                             (address_type.code = '05' or address_type.code = '06')", Org.getInternalOrg.id, params[:id]],
                                            :order => top_level_orgs_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "org_info",
           :locals => {:state_tlo_collection => @stateTlos,
                       :status_indicator => params[:status_indicator],
                       :state => @state,
                       :update_element => params[:update_element]}, :layout => false)
  end
  
  def update_org_hierarchy_table
    @org = Org.find(params[:id])
    @sup2sub = RelationshipCategory.find_by_code("01")    
    @orgList = Org.paginate(:page => params[:page], :select => "org.*",
                                        :joins => "inner join customer on org.customer_id = customer.id \
                                                   inner join customer_relationship on customer_relationship.customer_id = customer.id \
                                                   inner join relationship_category on relationship_category.id = customer_relationship.relationship_category_id",
                                        :conditions => ["customer_relationship.related_customer_id = ? and \
                                                         customer_relationship.effective <= ? and \
                                                         (customer_relationship.end is null or customer_relationship.end > ?) and \
                                                         customer_relationship.relationship_category_id = ?", @org.customer.id, Date.today.to_s, Date.today.to_s, @sup2sub.id],
                                        :order => org_hierarchy_sort_by_param(params["sort"]), :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "org_hierarchy_info",
           :locals => {:org_collection => @orgList,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :state => params[:state]}, :layout => false)
  end
  
  def update_large_org_table
    sql = "select top_level_org.*, org.name, count(*) as the_count from top_level_org \
           inner join org on top_level_org.top_level_org_id = org.id \
           where top_level_org.top_level_org_id != #{Org.getInternalOrg.id} \
           group by top_level_org.top_level_org_id having the_count > 10 order by " + org_sort_by_param(params["sort"])
    @top_levels = TopLevelOrg.paginate_by_sql(sql, :page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "org_bracket",
           :locals => {:tlo_collection => @top_levels,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :update_action => params[:action]}, :layout => false)
  end
  
  def update_mid_org_table
    sql = "select top_level_org.*, org.name, count(*) as the_count from top_level_org \
           inner join org on top_level_org.top_level_org_id = org.id \
           where top_level_org.top_level_org_id != #{Org.getInternalOrg.id} \
           group by top_level_org.top_level_org_id having the_count <= 10 and the_count > 3 order by " + org_sort_by_param(params["sort"])
    @top_levels = TopLevelOrg.paginate_by_sql(sql, :page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "org_bracket",
           :locals => {:tlo_collection => @top_levels,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :update_action => params[:action]}, :layout => false)
  end
  
  def update_small_org_table
    sql = "select top_level_org.*, org.name, count(*) as the_count from top_level_org \
           inner join org on top_level_org.top_level_org_id = org.id \
           where top_level_org.top_level_org_id != #{Org.getInternalOrg.id} \
           group by top_level_org.top_level_org_id having the_count <= 3 and the_count > 1 order by " + org_sort_by_param(params["sort"])
    @top_levels = TopLevelOrg.paginate_by_sql(sql, :page => params[:page], :per_page => PAGINATION_ROWS_PER_PAGE)
    render(:partial => "org_bracket",
           :locals => {:tlo_collection => @top_levels,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element],
                       :update_action => params[:action]}, :layout => false)
  end
  
  def select_us_state
    @selected_state = StateProvince.find(:first, :select => "state_province.*", :joins => "inner join country on state_province.country_id = country.id",
                      :conditions => ["country.id = ? and state_province.code = ?", Country.find_by_code("US").id, params[:id]])
  end
  
  def find_orgs
    joinsClause = ""
    conditionClause = ""
    if (params[:search_orgs][:org_group_category] == "TLO")
      conditionClause = "top_level_org.top_level_org_id = " + Org.getInternalOrg.id.to_s
      joinsClause = "inner join top_level_org on org.id = top_level_org.org_id"
    end
    
    stateId = params[:search_orgs][:state_id]
    if (!stateId.empty?)
      joinsClause << " inner join customer c on org.customer_id = c.id \
                       inner join customer_address ca on c.id = ca.customer_id \
                       inner join state_province sp on ca.state_province_id = sp.id \
                       inner join customer_group cg on c.customer_group_id = cg.id"
      (conditionClause << " and ") if (!conditionClause.empty?)
      conditionClause << ("sp.id = " + stateId + " and ca.address_type_id = 5")
    end
    
    searchString = params[:search_orgs][:name]
    if (searchString.nil? || searchString.empty?)
      @search_results = Org.find(:all, 
                                 :select => "org.name as org_name, sp.name as state_name, c.ucn as org_ucn, ca.address_line_1 as org_address, \
                                             cg.description as org_group, ca.city_name as org_city, ca.postal_code as org_zip_code", 
                                 :joins => joinsClause, :conditions => conditionClause)
    else
      (conditionClause << " and ") if (!conditionClause.empty?)
      conditionClause << "org.name like ?"
      @search_results = Org.find(:all, 
                                 :select => "org.name as org_name, sp.name as state_name, c.ucn as org_ucn, ca.address_line_1 as org_address, \
                                             cg.description as org_group, ca.city_name as org_city, ca.postal_code as org_zip_code",
                                 :joins => joinsClause, :conditions => [conditionClause, searchString+"%"])
    end
  end
  
  
  private
  
  def org_sort_by_param(sort_by_arg)
    return "the_count desc" if (sort_by_arg.nil?)
    case sort_by_arg
     when "org_name" then "org.name"
     when "num_descendants" then "the_count"
         
     when "org_name_reverse" then "org.name desc"
     when "num_descendants_reverse" then "the_count desc"
    end
  end
  
  def states_sort_by_param(sort_by_arg)
    return "state_province.name" if (sort_by_arg.nil?)
    case sort_by_arg
      when "statename" then "state_province.name, country.name"
      when "countryname" then "country.name, state_province.name"
      when "num_sam_customers" then "state_province.sam_customer_count, state_province.name"
      
      when "statename_reverse" then "state_province.name desc"
      when "countryname_reverse" then "country.name desc"
      when "num_sam_customers_reverse" then "state_province.sam_customer_count desc, state_province.name"
    end
  end
  
  def top_level_orgs_sort_by_param(sort_by_arg)
    return "org.name" if (sort_by_arg.nil?)
    case sort_by_arg
      when "org_name" then "org.name"
      when "org_name_reverse" then "org.name desc"
    end
  end
  
  def org_hierarchy_sort_by_param(sort_by_arg)
    return "org.name" if (sort_by_arg.nil?)
    case sort_by_arg
      when "org_name" then "org.name"
      when "org_name_reverse" then "org.name desc"
    end
  end
  
  def formBreadcrumbArray(org, breadcrumbArray, index)
    breadcrumbArray[index] = Array.new
    breadcrumbArray[index] << org
    parentsRels = getActiveParentRelationships(org)
    parentsRels.each do |rel|
      formBreadcrumbArray( rel.related_customer.org, breadcrumbArray, index + 1)
    end
    return breadcrumbArray
  end
  
  def isActiveParentRelationship?(rel)
    sup2subCat = RelationshipCategory.find_by_description("SUP2SUB")
    if ((rel.related_customer != nil) && (rel.customer != rel.related_customer) && (rel.effective <= Date.today) && 
       (rel.relationship_category == sup2subCat) && ((rel.end.nil?) || (rel.end > Date.today)))
       return true
    end
    return false
  end
  
  def getActiveParentRelationships(theOrg)
    relList = []
    theOrg.customer.parent_relationships.each do |rel|
      if (isActiveParentRelationship?(rel))
        relList << rel
      end
    end
    return relList
  end
  
  def getActiveChildRelationships(theOrg)
    relList = []
    theOrg.customer.child_relationships.each do |rel|
      if (isActiveParentRelationship?(rel))
        relList << rel
      end
    end
    return relList
  end
  
end
