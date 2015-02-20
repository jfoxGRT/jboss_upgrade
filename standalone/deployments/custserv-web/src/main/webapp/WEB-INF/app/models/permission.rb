class Permission < ActiveRecord::Base
  set_table_name "permission"
  has_many :user_permissions
  has_many :users, :through => :user_permissions
  belongs_to :role
  
  CODE_ADJUST_CUSTOMER_LICENSES = "ADJUST-LICENSES"
  CODE_MANAGE_SITEIDS = "MANAGE_SITEIDS"
  
  def self.edit_customer_sync_time
    find_by_code("SET_CUSTOMER_SYNC_HOUR")
  end  
  
  def self.manage_s_users
    find_by_code("MANAGE_S_USERS")
  end
  
  def self.manage_saplings
    find_by_code("SAP_REPO")  
  end
  
  def self.edit
    find_by_code("CUSTSERV-EDIT")
  end
  
  def self.assign_tasks
    find_by_code("CUSTSERV-TASKS")
  end
  
  def self.customer_resource_edit
    find_by_code("CUSTOMER-RESOURCE-EDIT")
  end
  
  def self.customer_site_edit
    find_by_code("SAMIWEB-EDIT")
  end
  
  # DEPRECATED --> TAKE OUT IN ITERATION 177
  def self.run_utilities
    find_by_code("RUN-UTILITIES")
  end
  
  def self.utilities_qa_functions
    find_by_code("UTILITIES-QA-FUNCTIONS")
  end  
  
  def self.banner_messaging
    find_by_code("BANNER_MESSAGING")
  end
  
  def self.lm_opt_in
    find_by_code("LM_OPT_IN")
  end
  
  def self.connect_now
    find_by_code("CONNECT_NOW")
  end
  
  def self.cust_maint_functions
    find_by_code("CUST_MAINT_FUNCTIONS")
  end 

  def self.decommission_licenses
	find_by_code("DECOMMISSION-LICENSES")
  end
  
  def self.cancel_license_reallocations
	find_by_code("CANCEL-SEAT-ACTIVITY")
  end
  
  def self.docitems_edit
	  find_by_code("DOCITEMS_EDIT")
  end
  
  def self.show_auth_password
    find_by_code("SHOW_AUTH_PASSWORD")
  end
  
  def self.show_export_batch_data
    find_by_code("SHOW_EXPORT_BATCH_DATA")
  end

  def self.run_export_batch_actions
    find_by_code("RUN_EXPORT_BATCH_ACTIONS")
  end
  
  def self.scat_access
    find_by_code("SCAT_ACCESS")
  end 

  def self.export_batch_blacklist_edit
    find_by_code("EXPORT_BATCH_BLACKLIST_EDIT")
  end
  
  def self.agent_diagnostic_scheduling
    find_by_code("AGENT_DIAGNOSTIC_SCHEDULING")
  end
  
  def self.advanced_debug
    find_by_code("ADVANCED_DEBUG")
  end
  
  def self.samc_resource_flag
    find_by_code("SAMC_RESOURCE_FLAG")
  end
  
  def self.manage_siteids
    find_by_code(CODE_MANAGE_SITEIDS)
  end
  
  def self.manage_cleverids
    find_by_code("CLEVER_ID")
  end
  
  # Purpose: Return list of permission available to a given customer
  def self.available_permissions_for_sam_customer(sam_customer)
    p_coll = Permission.find(:all, :conditions => ["user_type = ?", "c"])
    if !sam_customer.licensing_certified
      lic_p = Permission.find(:first, :conditions => ["user_type = ? and code = ?", "c", "LICENSE"])
      p_coll.delete(lic_p)
    end
    return p_coll
  end
  
end

# == Schema Information
#
# Table name: permission
#
#  id        :integer(10)     not null, primary key
#  code      :string(255)     not null
#  name      :string(255)     not null
#  user_type :string(1)       default("c"), not null
#  notes     :text
#

