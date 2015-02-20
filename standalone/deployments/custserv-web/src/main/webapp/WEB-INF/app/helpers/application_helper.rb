require 'rexml/document'
include REXML
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	
	def translate_audit_message_reason(reason_code)
		case reason_code
	    when "CVE" then "Corresponding Virtual Entitlement"
	    when "FLC" then "Finished Licensing Conversation"
			when "LCF" then "Licensing Conversation Failure"
			when "LMC" then "License Manager Conversion"
			when "LR" then "Manual License Reallocation"
			when "LSS" then "License Subscription Start"
			when "LSE" then "License Subscription End"
			when "D" then "Decommission"
			when "ELCC" then "Entitlement License Count Change"
			when "MCZ" then "Reset Count"
			when "SIPC" then "Server Initial License Manager Count"
			when "NAR" then "New Agent Report"
			when "NP" then "New Pool"
			when "NVE" then "New Virtual Entitlement"
			when "RLM" then "Reset License Manager"
			when "RLCDT" then "Resolve License Count Discrepancy Task"
			when "RLCIPT" then "Resolve License Count Integrity Problem Task"
			when "RPLCCT" then "Resolve Pending License Count Change Task"
			when "RS" then "Server Remediation"
			when "MRL" then "Adjust Total License Count"
			when "SD" then "Server Deactivation"
			when "ST" then "Server Transfer"
			when "TN" then "TMS Notify"
			when "ARLCDT" then "Automatic Resolution of Discrepancy"
			else "Unknown"
		end
	end
  
  def translate_school_status(status)
    case (status)
      when SamServerSchoolInfo.STATUS_NOT_RESOLVED then "Unresolved"
      when SamServerSchoolInfo.STATUS_TRANSITION then "In Transition"
      when SamServerSchoolInfo.STATUS_PENDING_CSI_VERIFICATION then "Pending CSI Verification After Submission"
      when SamServerSchoolInfo.STATUS_PENDING_CSI_VERIFICATION_FROM_INTERNAL_CHANGE then "Pending CSI Verification From Internal Change"
      when SamServerSchoolInfo.STATUS_PUBLISHED then "Published"
      when SamServerSchoolInfo.STATUS_RESOLVED then "Resolved"
    end
  end
  
  def translate_seat_activity_status(seat_activity)
    if (seat_activity.status == SeatActivity::STATUS_UNFINISHED)
        if (seat_activity.conversation_instance.nil?)
            "Not started"
        else
            "In progress.."
        end
    else 
      case seat_activity.status
        when SeatActivity::STATUS_FINISHED then "Complete"
        when SeatActivity::STATUS_CANCELLED then "Cancelled"
        when SeatActivity::STATUS_INTERRUPTED then "Combined"
        when SeatActivity::STATUS_FROZEN then "Frozen"
        when SeatActivity::STATUS_CONVERSATION_FAILURE then "Conversation Failure"
        when SeatActivity::STATUS_PENDING_START then "Pending Start"
        else "Unknown"
      end
    end
  end

  def translate_seat_activity_type(seat_activity)
    case seat_activity.activity_type
      when SeatActivity::TYPE_USER_MOVE        then "Move Licenses"
      when SeatActivity::TYPE_SYSTEM_GENERATED then "System Generated"
      when SeatActivity::TYPE_REMEDIATE_SERVER then "Remediate Server"
      when SeatActivity::TYPE_ALLOCATION_LEVEL_CHANGE  then "Server Allocation Level Change"
      else "Unknown"
    end
  end
  
  def translateUserType(pUser)
    case (pUser)
      when 'c' then "Customer"
      when 'a' then "Admin"
      when 's' then "Scholastic"
      else "-unknown-"
    end
  end
  
  def translateSamCustomerActiveStatus(status)
    status ? "Active" : "Inactive"
  end
  
  def translateYesOrNoStatus(status)
    status ? "Yes" : "No"
  end

  def translateManagerStatus(status_code)
    case status_code
      when 'n' then "Not Activated"
      when 'p' then "Pending"
      when 'a' then "Enabled"
      when 'd' then "Disabled"
    end
  end
  
  def translateTaskStatus(task)
    case (task.status)
      when Task.UNASSIGNED then "Unassigned"
      when Task.ASSIGNED then "Assigned"
      when Task.CLOSED then "Closed"
    end
  end
  
  def translateTaskStatusCode(task_status_code)
    case (task_status_code)
      when Task.UNASSIGNED then "Unassigned"
      when Task.ASSIGNED then "Assigned"
      when Task.CLOSED then "Closed"
    end
  end
  
  def translateTaskEventAction(task_event)
    case (task_event.action)
      when TaskEvent.ASSIGN then "Assigned To"
      when TaskEvent.UNASSIGN then "Released From"
      when TaskEvent.CLOSE then "Closed"
      when TaskEvent.REOPEN then "Reopened"
	  else "Unknown"
    end
  end
  
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files)}
  end

  def button_to_remote name, options = {}, html_options = nil
    button_to_function name, remote_function(options), html_options || options.delete(:html)
  end

  def currentUserHasPermission(permission)
    current_user.hasPermission?(permission)
  end

  def line_break(string)
    string.gsub("\n", '<br/>')
  end
  
  def generateAjaxIndicator(indicatorName)
    image_tag("3MA_processingbar.gif",
              :align => "absmiddle",
              :border => 0,
              :id => indicatorName,
              :style => "display: none;" )
  end
  
  def getSubdistricts(theOrg)
  districtGroupType = CustomerGroup.find_by_code("D")
  internalOrg = Customer.find_by_ucn(-1).org
  if (theOrg.top_level_orgs[0] == internalOrg)
    subs = Org.find(:all, :from => "org, top_level_org as tlo, customer as c",
                  :conditions => ["tlo.org_id = org.id and tlo.top_level_org_id = ? and org.customer_id = c.id and c.customer_group_id = ?", theOrg.id, districtGroupType.id])
  else
    distList = []
    subs = findLowerOrgsByType(theOrg, distList, districtGroupType)
  end
  return subs
end

def getSchools(theOrg)
  schoolGroupType = CustomerGroup.find_by_code("S")
  internalOrg = Customer.find_by_ucn(-1).org
  if (theOrg.top_level_orgs[0] == internalOrg)
    schools = Org.find(:all, :from => "org, top_level_org as tlo, customer as c",
                  :conditions => ["tlo.org_id = org.id and tlo.top_level_org_id = ? and org.customer_id = c.id and c.customer_group_id = ?", theOrg.id, schoolGroupType.id])
  else
    schoolList = []
    schools = findLowerOrgsByType(theOrg, schoolList, schoolGroupType)
  end
  return schools
end

def findLowerOrgsByType(org, theList, theGroup)
  getActiveChildRelationships(org).each do |rel|
    if (rel.customer.customer_group == theGroup)
      theList << rel.customer.org
    end
    findLowerOrgsByType(rel.customer.org, theList, theGroup)
  end
  return theList
end

def isUsingSamCentral?(theOrg)
  sc = SamCustomer.find(:first, :conditions => ["root_org_id = ?", theOrg.id])
  if (sc.nil?)
    return false;
  else
    return true;
  end
end

def getServers(theOrg)
  servers = SamServer.find(:all, :conditions => ["root_org_id = ?", theOrg.id])
  return servers
end

def isDistrictLevel?(theOrg)
  district = CustomerGroup.find_by_code("D")
  if (theOrg.customer.customer_group == district)
    return true;
  else
    return false;
  end  
end

def isOpen?(theOrg)
  openStatus = CustomerStatus.find_by_code("01")
  return (theOrg.customer.customer_status == openStatus)
end

def getEntitlementOrg(ent, eo_desc)
  # Get the bill-to and ship-to orgs
  if (eo_desc == "bill_to")
    eo_type = EntitlementOrgType.find_by_code("B")
  elsif (eo_desc == "ship_to")
    eo_type = EntitlementOrgType.find_by_code("S")
  else
    return nil
  end
  ent.entitlement_orgs.each do |eo|
    if (eo.entitlement_org_type == eo_type)
      return ((Customer.find(:first, :conditions => ["ucn = ?", eo.ucn])).org)
    end
  end
  return nil
end

def hasChildren
end

  def isActiveParentRelationship?(rel)
    sup2subCat = RelationshipCategory.find_by_description("SUP2SUB")
    if ((rel.related_customer != nil) && (rel.customer != rel.related_customer) && (rel.effective <= Date.today) && 
       (rel.relationship_category == sup2subCat) && ((rel.end.nil?) || (rel.end > Date.today)))
       return true
    end
    return false
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
  
  def page_list_info(collection)
    "Displaying entries #{collection.offset + 1} - #{collection.offset + collection.length} of #{collection.total_entries}"
  end
  
# def pagination_links_remote(paginator, block_element_name, action_name, loading_indicator, before_callback = nil, success_callback = nil)
#   page_options = {:window_size => 1, :link_to_current_page => false}
#   pagination_links_each(paginator, page_options) do |n|
#     options = {
#       :url => {:params => params.merge({:page => n, :action => action_name})},
#       :update => block_element_name,
#       :before => (before_callback.nil?) ? ("Element.show('" + loading_indicator + "')") : before_callback,
#       :success => (success_callback.nil?) ? ("Element.hide('" + loading_indicator + "')") : success_callback
#     }
#     html_options = {:href => url_for(:params => params.merge({:page => n, :action => action_name}))}
#     link_to_remote(n.to_s, options, html_options)
#   end
# end

def sort_td_class_helper(param)
  result = 'class="sortup"' if params[:sort] == param
  result = 'class="sortdown"' if params[:sort] == param + "_reverse"
  return result
end

def sort_link_helper(text, param, update_element, action_name, loading_indicator, before_callback = nil, success_callback = nil)
  key = param
  key += "_reverse" if params[:sort] == param
  options = {
      :url => {:params => params.merge({:sort => key, 
                                         :page => nil, 
                                         :action => action_name,
                                         :update_element => update_element,
                                         :status_indicator => loading_indicator})},
      :method => :post,
      :update => update_element,
      :before => (before_callback.nil?) ? ("Element.show('" + loading_indicator + "')") : before_callback,
      :success => (success_callback.nil?) ? ("Element.hide('" + loading_indicator + "')") : success_callback
  }
  html_options = {
    :title => "Sort by this field",
    :href => url_for(:params => params.merge({:sort => key, :page => nil,
                                               :action => action_name, :update_element => update_element,
                                               :status_indicator => loading_indicator})), :method => :post
  }
  link_to_remote(text, options, html_options)
end

  def getAlertCart
    return session[:alert_cart]
  end  
  
  def submit_to_remote_with_abort(name, value, options = {})
    options[:with] ||= 'Form.serialize(this.form)'
 
    options[:html] ||= {}
    options[:html][:type] = 'button'
    options[:html][:onclick] = "#{remote_function_with_abort(options)}; return false;"
    options[:html][:name] = name
    options[:html][:value] = value

    tag("input", options[:html], false)
  end
  
  def remote_function_with_abort(options)
    javascript_options = options_for_ajax(options) 
    update = ''
    
    abortElementValue = (options[:abort_element] + "Value")
    ajaxRequestObject = (value + "Request")
    
    if options[:update] && options[:update].is_a?(Hash)
    update  = []
    update << "success:'#{options[:update][:success]}'" if options[:update][:success]
    update << "failure:'#{options[:update][:failure]}'" if options[:update][:failure]
    update  = '{' + update.join(',') + '}'
    elsif options[:update]
    update << "'#{options[:update]}'"
    end

    function = (abortElementValue + " = document.getElementById('" + options[:abort_element] + "').value; ")
    
    function << update.empty? ? 
    (ajaxRequestObject + " = new Ajax.Request(") :
    (ajaxRequestObject + " = new Ajax.Updater(#{update}, ")

    url_options = options[:url]
    url_options = url_options.merge(:escape => false) if url_options.is_a?(Hash)
    function << "'#{url_for(url_options)}'"
    function << ", #{javascript_options})"
 
    function = "#{options[:before]}; #{function}" if options[:before]
    function = "#{function}; #{options[:after]}"  if options[:after]
    function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
    function = "if (confirm('#{escape_javascript(options[:confirm])}')) { #{function}; }" if options[:confirm]
 
    return function
  end
  
  
  def getAppTopicMessageAdditionalDetails(propertyName, propertyValue)
  additional_details = []
  case propertyName
    when "serverId" then
      begin
        theServer = SamServer.find(propertyValue)
      rescue ActiveRecord::RecordNotFound
      else
        additional_details[0] = ("Server Name: " + theServer.name)
        additional_details[1] = ("Sam Customer: " + theServer.sam_customer.root_org.name)
      end
    when "subcommunityId" then
      begin
        theSubcommunity = Subcommunity.find(propertyValue)
      rescue ActiveRecord::RecordNotFound
      else
        additional_details[0] = theSubcommunity.name
      end
    when "entitlementId" then
      begin
        theEntitlement = Entitlement.find(propertyValue)
      rescue ActiveRecord::RecordNotFound
      else
        additional_details[0] = ("Product Description: " + theEntitlement.product.description)
        additional_details[1] = ("Sam Customer: " + ((theEntitlement.sam_customer.nil?) ? "(unassigned)" : theEntitlement.sam_customer.root_org.name.strip))
        additional_details[2] = ("Order #: " + theEntitlement.order_num)
        additional_details[3] = ("Invoice #: " + theEntitlement.invoice_num)
      end
    when "userId" then
      begin
        theUser = User.find(propertyValue)
      rescue ActiveRecord::RecordNotFound
      else
        additional_details[0] = ("User Name: " + theUser.first_name + " " + theUser.last_name)
        additional_details[1] = ("User Email: " + theUser.email)
        additional_details[2] = ("User Type: " + theUser.user_type)
        (additional_details[3] = ("Sam Customer: " + theUser.sam_customer.root_org.name)) if (theUser.user_type == 'c')
      end
    when "schoolInfoId" then
      begin
        theSchool = SamServerSchoolInfo.find(propertyValue)
      rescue ActiveRecord::RecordNotFound
      else
        additional_details[0] = ("School Name: " + theSchool.name)
        additional_details[1] = ("Server Name: " + theSchool.sam_server.name)
        additional_details[2] = ("Sam Customer: " + theSchool.sam_server.sam_customer.root_org.name.strip)
      end
    when "emailMessageId" then
      begin
        theEmail = EmailMessage.find(propertyValue)
      rescue ActiveRecord::RecordNotFound
      else
        additional_details[0] = ("Email Type: " + theEmail.email_type.description)
        if(!theEmail.user.nil?)
          additional_details[1] = ("Email Address: " + theEmail.user.email)
          additional_details[2] = ("Sam Customer: " + ((theEmail.user.sam_customer.nil?) ? "(unassigned)" : theEmail.user.sam_customer.root_org.name.strip))
        end
      end
    else
        additional_details[0] = ""
  end
  return additional_details
end
  
  
  # convenience method that returns the formatted date string without risking null pointer exception.
  # handles type checking as well.
  def safe_date_format(date)
    return nil unless date
    
    return date.strftime(DATE_FORM) if date.class == 'Date'
    
    Date.parse(date).strftime(DATE_FORM) # presumably date.class is 'String' at this point, but leave it to Date.parse()
  end
  
  
  # return the generated HTML for a true or false boolean icon based on the provided expression.
  def boolean_icon(expression)
    expression ? image_tag("choice-yes.gif") : image_tag("choice-no.gif")
  end
end
