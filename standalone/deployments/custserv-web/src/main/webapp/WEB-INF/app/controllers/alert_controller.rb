require 'entitlement_manager/defaultDriver'
require 'sam_customer_manager/defaultDriver'
require 'user_manager/defaultDriver'

class AlertController < ApplicationController

  include EntitlementManager
  include SamCustomerManager
  include UserManager
  
  layout 'cs_layout'

  

  def index
  end  
  
  #-----------------------------------#
  # "UNASSIGNED SAM CUSTOMER" ACTIONS #
  #-----------------------------------# 
  
  def unassigned_sam_customers
  
    alertCode = "UNASSIGNED_SAM_CUSTOMER"
    @unassignedSamCustomers = (AlertInstance.find_all()).select {|a| a.alert.code == alertCode}
    #if (@alert_cart = find_alert_cart)
    #  @alert_cart.print()
    #end
  end
  
  def assign_sam_customer_rootorg
  
    #update the sam customer's root org
    selected_org = Org.find(params[:selected_org])
    selected_alert_instance = AlertInstance.find(params[:selected_alert])
    
    # refresh the alert cart
    selected_alert_instance.status = "1"
    #@alert_cart = find_alert_cart
    #@alert_cart.remove_alert(selected_alert_instance)
    #@alert_cart.print
    selected_alert_instance.save!
    
    # invoke the sam customer manager to finish the processing
    samCustomerManager = SamCustomerManagerPortType.new( SAM_CUSTOMER_MANAGER_URL )
  
    param = UpdateSamCustomer.new
    param.samCustomerId = selected_alert_instance.sam_customer.id
    param.rootOrgId = selected_org.id
    
    result = samCustomerManager.updateSamCustomer( param )
        
    flash[:notice] = "Root Organization Assigned"
    redirect_to(:action => :unassigned_sam_customers)
    
  end
  
  def cancel_sam_customer_assign
    cancelAlertOwnership(params[:id])
    flash[:notice] = "Cancelled Unassigned Sam Customer"
    redirect_to(:action => :unassigned_sam_customers)
  end
  
  
  #--------------------#
  # "NO USER" ACTIONS  #
  #--------------------#
  
  def no_users
    alertCode = "NO_USERS"
    @noUserAIs = AlertInstance.find(:all, :select => "distinct(sam_customer_id), entitlement_id, assigned_user_id, status, long_message, ai.id",
                                              :joins => "as ai inner join alert a on ai.alert_id = a.id",
                                              :group => "sam_customer_id", :conditions => ["a.code = ?", alertCode])   
  end
  
  def add_user
    @chosen_alert_instance = AlertInstance.find(params[:alert_instance_id])
    if (takeAlertOwnership(@chosen_alert_instance) < 0)
      flash[:notice] = "Someone already nabbed that User.. woo ahahaha!"
      redirect_to(:action => :no_users)
    end
  end
  
  def new_user
  
    #update the alert instance
    selected_alert_instance = AlertInstance.find(params[:user][:alert_instance_id])
    
    closeAlert(selected_alert_instance)
    
    # invoke the user manager to finish the processing
    userManager = UserManagerPortType.new( USER_MANAGER_URL )
    
    param = CreateOriginalCustomerUser.new
    param.email = params[:user][:email]
    param.firstName = params[:user][:first_name]
    param.lastName = params[:user][:last_name]
    param.samCustomerId = selected_alert_instance.sam_customer.id
    
    result = userManager.createOriginalCustomerUser( param ).out
    if result.success
      flash[:notice] = "New User Added"
    else
      selected_alert_instance.status = nil
      selected_alert_instance.save!
      if result.errorCode == 0
        flash[:notice] = "That email address is already in use"
      else
        flash[:notice] = "Error occurred adding new user. Please try again later"
      end
    end
    redirect_to(:action => :no_users)    
  end
  
  def cancel_add_user
    cancelAlertOwnership(params[:id])
    flash[:notice] = "Cancelled Add User"
    redirect_to(:action => :no_users)
  end
  
  
  
  #-----------------------------------#
  # "UNASSIGNED ENTITLEMENT" ACTIONS  #
  #-----------------------------------#
  
  
  def unassigned_entitlements
  
    alertCode = "INDETERMINABLE_ROOT_ORG"
    @unassignedEntitlements = AlertInstance.find(:all, :select => "alert_instance.*", :joins => "inner join alert on alert_instance.alert_id = alert.id",
                                            :conditions => ["alert.code = ?", alertCode])
    @user_map = User.find_all_by_user_type(User.TYPE_SCHOLASTIC, :order => "last_name").collect {|u| [u.last_name + ", " + u.first_name, u.id]}
    @user = current_user
  end
  
  def assign_rootorg
  
    #update the entitlement's root org
    selected_org = Org.find(params[:selected_org])
    selected_alert_instance = AlertInstance.find(params[:selected_alert])
    entitlement = Entitlement.find(selected_alert_instance.entitlement.id)
    
    
    closeAlert(selected_alert_instance)
    
    # invoke the entitlement manager to finish the processing
    entitlementManager = EntitlementManagerPortType.new( ENTITLEMENT_MANAGER_URL )
  
    param = UpdateRootOrg.new
    param.entitlementId = entitlement.id
    param.orgId = selected_org.id
    
    result = entitlementManager.updateRootOrg( param )
        
    flash[:notice] = "Root Organization Assigned"
    redirect_to(:action => :unassigned_entitlements)
    
  end
  
  def cancel_entitlement_assign
    cancelAlertOwnership(params[:id])
    flash[:notice] = "Cancelled Assignment"
    redirect_to(:action => :unassigned_entitlements)
  end
  
  
  #-----------------------------------#
  # "UNRECOGNIZED TMS ITEM" ACTIONS   #
  #-----------------------------------#
  
  
  def unrecognized_tms_items
    alertCode = "UNRECOGNIZED_ITEM_NUMBER"
    @unrecognizedItems = AlertInstance.find(:all, :select => "alert_instance.*", :joins => "inner join alert on alert_instance.alert_id = alert.id",
                                            :conditions => ["alert.code = ?", alertCode])
    @alert_cart.print() if (@alert_cart = find_alert_cart) 
  end
  
  def handle_unrecognized_tms_item
    if (takeAlertOwnership(@chosen_alert_instance = AlertInstance.find(params[:alert_instance_id])) >= 1)
      @alert_cart.print
    else
      flash[:notice] = "Someone already took that task"
      redirect_to(:action => :unrecognized_tms_items)
    end  
  end
  
  def close_unrecognized_tms_item
    #update the alert instance
    selected_alert_instance = AlertInstance.find(params[:alert_instance_id])
    
    # refresh the alert cart
    selected_alert_instance.status = "1"
    @alert_cart = find_alert_cart
    @alert_cart.remove_alert(selected_alert_instance)
    @alert_cart.print
    selected_alert_instance.save!
    
    flash[:notice] = "Closed Alert"
    redirect_to(:action => :unrecognized_tms_items)
    
  end
  
  def cancel_unrecognized_tms_item
    cancelledAlertInstance = AlertInstance.find(params[:alert_instance_id])
    cancelledAlertInstance.assigned_user = nil
    @alert_cart = find_alert_cart
    @alert_cart.remove_alert(cancelledAlertInstance)
    @alert_cart.print
    cancelledAlertInstance.save!
    flash[:notice] = "Cancelled Alert"
    redirect_to(:action => :unrecognized_tms_items)
  end
  
  #--------------------------------------#
  # "LICENSE COUNT DISCREPANIES" ACTIONS #
  #--------------------------------------#

  def license_count_discrepancies
    alert_code = "LICENSING_BALANCE"
    @lcd_alerts = AlertInstance.find(:all, :conditions => ["alert_id = ?", Alert.find_by_code(alert_code)])
  end

  
  #----------------#
  # COMMON ACTIONS #
  #----------------#
  
  def assign_revoke_task
    if (params[:revoke_task] == "1" )
      cancelAlertOwnership(params[:alert_instance_id])
      redirect_to(:action => :unassigned_entitlements)
      return
    elsif (params[:assign_task] == "1")
      @chosen_alert_instance = AlertInstance.find(params[:alert_instance_id])
      @ueAlertType = Alert.getUnassignedEntitlementsAlert
      #if assigning the alert was successful, just return to the list of unassigned entitlements
      if (assignAlertOwnership(@chosen_alert_instance, params[:user][:id]) >= 1)
        redirect_to(:action => :unassigned_entitlements)
        return
      #otherwise, if the assignment was unsuccessful, inform the user and return to the list of unassigned entitlements
      else
        flash[:notice] = "Someone already took that task"
        if (@chosen_alert_instance.alert == @ueAlertType)
          redirect_to(:action => :unassigned_entitlements)
        else
          redirect_to(:action => :unassigned_sam_customers)
        end
      end
    else
      redirect_to(:action => :top_level_districts, :alert_instance_id => params[:alert_instance_id])
    end
  end
   
  def top_level_districts
    @chosen_alert_instance = AlertInstance.find(params[:alert_instance_id])
    @ueAlertType = Alert.getUnassignedEntitlementsAlert
    # if the page should be loaded
    if (takeAlertOwnership(@chosen_alert_instance) >= 1)
      if (@chosen_alert_instance.alert == @ueAlertType)
          @topLevelOrgList = formTopLevelOrgList(@chosen_alert_instance.org1, @chosen_alert_instance.org2)
          @targetSubmitAction = "assign_rootorg"
      else
          @topLevelOrgList = formTopLevelOrgList(@chosen_alert_instance.org1, nil)
          @targetSubmitAction = "assign_sam_customer_rootorg"
      end
    # otherwise, the alert instance has already been reserved
    else
      flash[:notice] = "Someone already took that task"
      if (@chosen_alert_instance.alert == @ueAlertType)
          redirect_to(:action => :unassigned_entitlements)
      else
          redirect_to(:action => :unassigned_sam_customers)
      end
    end
  end
  
  
  def org_hierarchy
  
    #@alert_cart = find_alert_cart
    @chosen_alert_instance = AlertInstance.find(params[:alert_instance_id])
    @ueAlertType = Alert.getUnassignedEntitlementsAlert
    @targetSubmitAction = (@chosen_alert_instance.alert == @ueAlertType) ? "assign_rootorg" : "assign_sam_customer_rootorg"
  
    districtCustomerGroup = CustomerGroup.find_by_code("D")
    schoolCustomerGroup = CustomerGroup.find_by_code("S")
    
    @org = Org.find(params[:id])
    @orgList = []
    getActiveChildRelationships(@org).each do |rel|
      @orgList << rel.customer.org
    end
    
    @orgList = @orgList.sort {|x,y| x.name <=> y.name}
    
    # Populate the breadcrumb array
    @breadcrumbArray = []
    @breadcrumbArray = formBreadcrumbArray(@org, @breadcrumbArray, 0)
    @breadcrumbArray = @breadcrumbArray.reverse
  
  end
  
private

  def assignAlertOwnership(theAlertInstance, theUserId)
    numberOfRowsAffected = 1
    if ((theAlertInstance.status.nil?) && (!theAlertInstance.assigned_user.nil?) && (theAlertInstance.assigned_user.id == theUserId))
      return numberOfRowsAffected
    end
    numberOfRowsAffected = AlertInstance.update_all(["assigned_user_id = ?, assigning_user_id = ?, date_assigned = ?", theUserId, session[:user], Time.now], 
                                                    ["id = ? and assigned_user_id is null", theAlertInstance.id])
    return numberOfRowsAffected
  end

  def takeAlertOwnership(theAlertInstance)
    numberOfRowsAffected = 1
    if ((theAlertInstance.status.nil?) && (!theAlertInstance.assigned_user.nil?) && (theAlertInstance.assigned_user.id == session[:user]))
      return numberOfRowsAffected
    end
    numberOfRowsAffected = AlertInstance.update_all(["assigned_user_id = ?, assigning_user_id = ?, date_assigned = ?", session[:user], session[:user], Time.now], 
                                                    ["id = ? and assigned_user_id is null", theAlertInstance.id])
    return numberOfRowsAffected
  end
  
  def cancelAlertOwnership(alertInstanceId)
    cancelledAlertInstance = AlertInstance.find(alertInstanceId)
    cancelledAlertInstance.assigned_user = nil
    cancelledAlertInstance.assigning_user = nil
    cancelledAlertInstance.date_assigned = nil
    cancelledAlertInstance.save!
  end
  
  def closeAlert(alertInstance)
    alertInstance.status = 1
    alertInstance.date_closed = Time.now
    alertInstance.save!
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

  def formTopLevelOrgList(o1, o2)
    districtList = []
    nondistrictList = []
    orgList = []
    if (o1.isTopLevel?)
      if (o1.isDistrict?)
        districtList << o1
      else
        nondistrictList << o1
      end
    else
      o1.top_level_orgs.each do |o|
        if (o.isDistrict?)
          districtList << o
        else
          nondistrictList << o
        end
      end
    end
    
    if (!o2.nil?)
    
      if (o2.isTopLevel?)
        if (o2.isDistrict? && !districtList.include?(o2) && !nondistrictList.include?(o2))
          districtList << o2
        elsif (!nondistrictList.include?(o2) && !districtList.include?(o2))
          nondistrictList << o2
        end
      else
        o2.top_level_orgs.each do |p|
            if (p.isDistrict? && !districtList.include?(p) && !nondistrictList.include?(p))
              districtList << p
            elsif (!nondistrictList.include?(p) && !districtList.include?(p))
              nondistrictList << p
            end
        end
      end
      
    end
    
    districtList = districtList.sort {|x,y| x.name <=> y.name}
    nondistrictList = nondistrictList.sort {|x,y| x.name <=> y.name}
    
    districtList.each do |dl|
      orgList << dl
    end
    nondistrictList.each do |nl|
      orgList << nl
    end
    
    return orgList
    
  end

  def find_alert_cart
    if (session[:alert_cart])
      return session[:alert_cart]
    end
    alert_cart = AlertCart.new
    assigned_alerts = AlertInstance.find(:all, :conditions => ["assigned_user_id = ? and status is null", current_user.id])
    assigned_alerts.each do |aa|
      alert_cart.add_alert(aa)
    end
    session[:alert_cart] = alert_cart
    return session[:alert_cart]
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
