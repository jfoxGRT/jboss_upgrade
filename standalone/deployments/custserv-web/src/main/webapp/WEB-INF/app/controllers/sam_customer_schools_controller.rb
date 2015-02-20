
class SamCustomerSchoolsController < SamCustomersController
  
  before_filter :set_breadcrumb
  
  layout 'default'
  
  def index
    sam_customer_id = params[:sam_customer_id]
    @schools = get_sam_customer_schools(sam_customer_id)
    
    @search_topic = "Schools"
    @table_support = true
  end
  
  def show
    @school = SamServerSchoolInfo.find(params[:id])
    @sam_server = @school.sam_server
    @org = @school.org
    @products = get_products
    @classes = @school.sam_server_class_infos
        
    @classes.each do |my_class| 
    	my_class.communities_string = my_class.find_communities
    end
    
  end
  
  def edit
    puts "params: #{params.to_yaml}"
    @school = SamServerSchoolInfo.find(params[:id])
    postal_code = @school.postal_code if @school.postal_code.length > 0
    zip_code = postal_code.slice(0,5).to_i if(postal_code && postal_code.length >= 5)    
    if (zip_code)
        school_name = @school.name.strip.upcase
      search_word = nil
      if (school_name.length < 5)
        search_word = school_name
      else
        i = 0
        school_name_parts = school_name.scan(/\w+/)
        while(search_word.nil? && i < school_name_parts.length)
          next_term = school_name_parts[i]
          search_word = next_term if (next_term.length >= 5)
          i += 1
        end
        search_word = school_name_parts[0] if (search_word.nil?)
      end
      puts "search word: #{search_word}"
      @orgs = Org.find_by_keyword_and_zip_code(search_word, zip_code) if (zip_code != 0)
    else
      @orgs = []
    end
  end
  
  def update
    puts "params: #{params.to_yaml}"
    if(!params[:selected_org].nil? && params[:selected_org] != "0")
      selected_org = Org.find(params[:selected_org])
      SamServerSchoolInfo.update(params[:id], {:org => selected_org})
      flash[:notice] = "School was matched successfully!"
    else
      ucn_as_int = params[:ucn].strip.to_i
      if (ucn_as_int != 0)
        customer = Customer.find_by_ucn(params[:ucn])
        if (customer)
          SamServerSchoolInfo.update(params[:id], {:org => customer.org})
          flash[:notice] = "School was matched successfully!"
        else
          flash[:notice] = "Specified UCN is not valid.  Please try again."
          redirect_to(:action => :edit)
          return
        end
      else
        flash[:notice] = "Specified UCN is not valid.  Please try again."
        redirect_to(:action => :edit)
        return
      end
      
    end
    redirect_to(:action => :index)
  end
  
    
  #################
  # AJAX ROUTINES #
  #################
  
  def get_sam_customer_schools(sam_customer_id)
    SamServerSchoolInfo.find(:all, :select => "sssi.*", 
                                   :joins => "sssi inner join sam_server ss on sssi.sam_server_id = ss.id",
                                   :conditions => ["ss.status = 'a' and ss.sam_customer_id = ?", sam_customer_id] )
  end
  
  
  def auth_users_by_school
    @auth_users_by_school = get_school_auth_users
  end
  
  def update_school_auth_users
    @auth_users_by_school = get_school_auth_users(params[:sort].nil? ? "auth_user_id" : params[:sort])
    @products = get_products
    
    render(:partial => "school_auth_users_table", :locals => {:auth_user_collection => @auth_users_by_school, 
                                                              :products_collection => @products, 
                                                              :status_indicator => "auth_users_loading_indicator",
                                                              :update_element => "school_auth_users_table",
                                                              :school_id => params[:school_id]})
  end
  
  
  def get_school_auth_users(sortby="auth_user_id")
    AuthUser.find(:all, :select => "distinct au.*", 
                        :joins => "au INNER JOIN sam_server_user ssu ON ssu.auth_user_id = au.id 
                                   INNER JOIN sam_server ss ON ssu.sam_server_id = ss.id 
                                   INNER JOIN sam_server_school_info sssi ON sssi.sam_server_id = ss.id 
                                   INNER JOIN sam_server_school_info_user_mapping sssium ON (sssium.sam_school_id = sssi.sam_school_id AND sssium.user_id = ssu.user_id)", 
                        :conditions => ["sssi.id = ?", params[:school_id]], 
                        :order => school_auth_users_sort_by_param(sortby))
  end
  
  
  def get_products #note that no user sorting is supported here, just default ascending alphabetical
    #Service entitlements are by sam_customer or by org(school). So, all auth users for a given school will have the same product access related to that school
    @products_by_school = Product.find(:all, :select => "DISTINCT p.description",
                                       :joins => "p INNER JOIN entitlement e ON p.id = e.product_id 
                                                  INNER JOIN sam_customer sc ON e.sam_customer_id = sc.id 
                                                  INNER JOIN org o ON (e.install_to_org_id = o.id OR e.bill_to_org_id = o.id) 
                                                  INNER JOIN sam_server_school_info sssi ON o.id = sssi.org_id",
                                       :conditions => ["NOT p.sam_server_product 
                                                        AND e.subscription_start IS NOT null 
                                                        AND (e.subscription_end IS null OR e.subscription_end > now())
                                                        AND sssi.id = ?", params[:school_id]],
                                       :order => "p.description DESC")
    
    #also need all the products the customer has at customer level. ITS, DTZ, and SU can't be customer level. We'll remove duplicates and sort later
    #TODO: check for hosted with regard to DTS, DTZ, SU 
    @products_by_district = Product.find(:all, :select => "DISTINCT p.description", 
                                         :joins => "p INNER JOIN entitlement e ON p.id = e.product_id 
                                                    INNER JOIN product_group pg ON p.product_group_id = pg.id 
                                                    INNER JOIN org o ON (e.install_to_org_id = o.id OR e.bill_to_org_id = o.id) 
                                                    INNER JOIN sam_customer sc ON o.id = sc.root_org_id 
                                                    INNER JOIN sam_server ss ON sc.id = ss.sam_customer_id 
                                                    INNER JOIN sam_server_school_info sssi ON ss.id = sssi.sam_server_id", 
                                         :conditions => ["NOT p.sam_server_product 
                                                          AND pg.code NOT IN('DTS', 'DTZ', 'SU') 
                                                          AND e.subscription_start IS NOT null 
                                                          AND (e.subscription_end IS null OR e.subscription_end > now()) 
                                                          AND sssi.id = ?", params[:school_id]],
                                         :order => "p.description DESC")
    
    products = removeDuplicatesFromArray(@products_by_school + @products_by_district) #join arrays and remove duplicates
    products.sort! { |a,b| a.description.downcase <=> b.description.downcase }
  end
  
  
  private
  
  def school_auth_users_sort_by_param(sort_by_arg="auth_user_id")
    case sort_by_arg
      when "auth_user_id"              then "au.id"
      when "auth_user_id_reverse"      then "au.id DESC"
      when "username"                  then "LOWER(au.username)"
      when "username_reverse"          then "LOWER(au.username) DESC"
      when "auth_user_type"            then "au.type"
      when "auth_user_type_reverse"    then "au.type DESC"
      when "uuid"                      then "au.uuid"
      when "uuid_reverse"              then "au.uuid DESC"
      when "created_at"                then "au.created_at"
      when "created_at_reverse"        then "au.created_at desc"
      when "updated_at"                then "au.updated_at"
      when "updated_at_reverse"        then "au.updated_at desc"
      when "enabled"                   then "au.enabled"
      when "enabled_reverse"           then "au.enabled desc"
      else "id" #should never be reached
    end
  end
  
  def removeDuplicatesFromArray(originalArray) #uniq member method doesn't work for arrays of ActiveRecord.
    newArray = Array.new
    originalArray.each do |currentElement|
      isDuplicate = false
      newArray.each do |elementToCheckAgainst|
        if(elementToCheckAgainst.description.downcase == currentElement.description.downcase)
          isDuplicate = true
          break
        end
      end
      if(!isDuplicate)
        newArray << currentElement
      end
    end
    
    return newArray
  end
  
  def set_breadcrumb
    @site_area_code = SCHOOLS_ON_SAM_SERVERS_CODE
  end
end
