class CreateBaseSchema < ActiveRecord::Migration
  def self.up    
  create_table "address_type", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string
  end

  create_table "agent", :force => true do |t|
    t.column "created_at",          :datetime,               :null => false
    t.column "updated_at",          :datetime,               :null => false
    t.column "sam_server_id",       :integer, :references => nil
    t.column "cookie",              :string,   :limit => 36, :null => false
    t.column "cookie_verified",     :boolean
    t.column "jre_version",         :integer
    t.column "microloader_version", :integer
    t.column "next_poll_at",        :datetime
    t.column "os_series",           :string
    t.column "cpu_bits",            :string
    t.column "os_family",           :string
    t.column "cpu_type",            :string
  end

  add_index "agent", ["cookie"], :name => "index_agent_on_cookie", :unique => true
  add_index "agent", ["sam_server_id"], :name => "sam_server_id_2", :unique => true
  add_index "agent", ["sam_server_id"], :name => "sam_server_id_3", :unique => true
  add_index "agent", ["sam_server_id"], :name => "sam_server_id"

  create_table "agent_community", :force => true do |t|
    t.column "agent_id", :integer, :null => false, :references => nil
    t.column "name",     :string
    t.column "value",    :integer
  end

  add_index "agent_community", ["agent_id"], :name => "agent_id"

  create_table "agent_plugin", :force => true do |t|
    t.column "agent_id", :integer, :references => nil
    t.column "value",    :integer
    t.column "name",     :string
  end

  add_index "agent_plugin", ["agent_id"], :name => "agent_id"

  create_table "alert", :force => true do |t|
    t.column "code",           :string,  :null => false
    t.column "target_role_id", :integer, :null => false, :references => nil
    t.column "msg_type",       :string,  :null => false
  end

  add_index "alert", ["target_role_id"], :name => "target_role_id"

  create_table "alert_instance", :force => true do |t|
    t.column "alert_id",                 :integer,  :null => false, :references => nil
    t.column "message",                  :string,   :null => false
    t.column "conversation_instance_id", :integer, :references => nil
    t.column "server_id",                :integer, :references => nil
    t.column "user_id",                  :integer, :references => nil
    t.column "root_org_id",              :integer, :references => nil
    t.column "org_id",                   :integer, :references => nil
    t.column "created_at",               :datetime, :null => false
  end

  create_table "auth_src_verified", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
    t.column "text",        :string
  end

  create_table "collection_method", :force => true do |t|
    t.column "code",        :string
    t.column "indicator",   :string
    t.column "description", :string
    t.column "text",        :string
  end

  create_table "community", :force => true do |t|
    t.column "code", :string
    t.column "name", :string
  end

  create_table "conversation_command", :force => true do |t|
    t.column "command_id",                     :string,  :null => false, :references => nil
    t.column "plugin_id",                      :string,  :null => false, :references => nil
    t.column "conversation_state_instance_id", :integer, :null => false, :references => nil
    t.column "success",                        :integer
  end

  add_index "conversation_command", ["conversation_state_instance_id"], :name => "conversation_state_instance_id"

  create_table "conversation_command_error", :force => true do |t|
    t.column "name",                    :string,                  :null => false
    t.column "value",                   :string,  :limit => 2048
    t.column "conversation_command_id", :integer,                 :null => false, :references => nil
  end

  add_index "conversation_command_error", ["conversation_command_id"], :name => "conversation_command_id"

  create_table "conversation_command_property", :force => true do |t|
    t.column "name",                    :string,  :null => false
    t.column "value",                   :string
    t.column "conversation_command_id", :integer, :null => false, :references => nil
  end

  add_index "conversation_command_property", ["conversation_command_id"], :name => "conversation_command_id"

  create_table "conversation_current_state", :force => true do |t|
    t.column "conversation_instance_id",       :integer, :references => nil
    t.column "conversation_state_instance_id", :integer, :references => nil
  end

  add_index "conversation_current_state", ["conversation_instance_id"], :name => "conversation_instance_id"
  add_index "conversation_current_state", ["conversation_state_instance_id"], :name => "conversation_state_instance_id"

  create_table "conversation_instance", :force => true do |t|
    t.column "adapter_identifier",                      :string
    t.column "conversation_identifier",                 :string
    t.column "agent_id",                                :integer,                                 :null => false, :references => nil
    t.column "created_at",                              :datetime,                                :null => false
    t.column "updated_at",                              :datetime,                                :null => false
    t.column "started",                                 :datetime
    t.column "completed",                               :datetime
    t.column "result_type_id",                          :integer,                                 :null => false, :references => nil
    t.column "result_msg",                              :string,   :limit => 2048
    t.column "retry_timeout_end",                       :datetime
    t.column "retry_parent_conversation_instance_id",   :integer, :references => nil
    t.column "retry_original_conversation_instance_id", :integer, :references => nil
    t.column "priority",                                :integer,                  :default => 0
  end

  add_index "conversation_instance", ["agent_id"], :name => "agent_id"
  add_index "conversation_instance", ["result_type_id"], :name => "result_type_id"

  create_table "conversation_instance_variable", :force => true do |t|
    t.column "conversation_instance_id", :integer, :references => nil
    t.column "name",                     :string
    t.column "value",                    :string
  end

  add_index "conversation_instance_variable", ["conversation_instance_id"], :name => "conversation_instance_id"

  create_table "conversation_result_type", :force => true do |t|
    t.column "code", :string
    t.column "name", :string
  end

  create_table "conversation_state_instance", :force => true do |t|
    t.column "conversation_instance_id", :integer, :references => nil
    t.column "state_identifier",         :string
    t.column "created_at",               :datetime, :null => false
    t.column "entered",                  :datetime
    t.column "exited",                   :datetime
  end

  add_index "conversation_state_instance", ["conversation_instance_id"], :name => "conversation_instance_id"

  create_table "country", :force => true do |t|
    t.column "code",     :string, :limit => 3
    t.column "iso_code", :string
    t.column "name",     :string, :limit => 75
  end

  create_table "customer", :force => true do |t|
    t.column "ucn",                 :integer,                :null => false
    t.column "customer_group_id",   :integer,                :null => false, :references => nil
    t.column "customer_type_id",    :integer,                :null => false, :references => nil
    t.column "customer_status_id",  :integer, :default => 1, :null => false, :references => nil
    t.column "customer_added_date", :date
  end

  add_index "customer", ["ucn"], :name => "uq_customer_realm_idx", :unique => true
  add_index "customer", ["customer_group_id"], :name => "customer_group_id"
  add_index "customer", ["customer_type_id"], :name => "customer_type_id"
  add_index "customer", ["customer_status_id"], :name => "customer_status_id"

  create_table "customer_address", :force => true do |t|
    t.column "customer_id",         :integer, :references => nil
    t.column "address_type_id",     :integer, :references => nil
    t.column "usps_record_type_id", :integer, :references => nil
    t.column "address_line_1",      :string
    t.column "address_line_2",      :string
    t.column "address_line_3",      :string
    t.column "address_line_4",      :string
    t.column "address_line_5",      :string
    t.column "city_name",           :string
    t.column "state_province_id",   :integer, :references => nil
    t.column "postal_code",         :string
    t.column "county_code",         :string
    t.column "country_id",          :integer, :references => nil
    t.column "effective_date",      :datetime, :null => false
  end

  add_index "customer_address", ["customer_id"], :name => "customer_id"
  add_index "customer_address", ["address_type_id"], :name => "address_type_id"
  add_index "customer_address", ["usps_record_type_id"], :name => "usps_record_type_id"
  add_index "customer_address", ["state_province_id"], :name => "state_province_id"
  add_index "customer_address", ["country_id"], :name => "country_id"

  create_table "customer_group", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "customer_relationship", :force => true do |t|
    t.column "customer_id",              :integer, :references => nil
    t.column "related_customer_id",      :integer, :references => nil
    t.column "relationship_type_id",     :integer, :null => false, :references => nil
    t.column "effective",                :date,    :null => false
    t.column "end",                      :date
    t.column "relationship_category_id", :integer, :null => false, :references => nil
  end

  add_index "customer_relationship", ["customer_id"], :name => "customer_id"
  add_index "customer_relationship", ["related_customer_id"], :name => "related_customer_id"
  add_index "customer_relationship", ["relationship_type_id"], :name => "relationship_type_id"
  add_index "customer_relationship", ["relationship_category_id"], :name => "relationship_category_id"

  create_table "customer_role", :force => true do |t|
    t.column "customer_id",           :integer, :references => nil
    t.column "related_customer_id",   :integer, :references => nil
    t.column "relationship_type_id",  :integer, :references => nil
    t.column "role_group_id",         :integer, :references => nil
    t.column "role_type_id",          :integer, :references => nil
    t.column "related_role_group_id", :integer, :references => nil
    t.column "related_role_type_id",  :integer, :references => nil
  end

  add_index "customer_role", ["customer_id"], :name => "customer_id"
  add_index "customer_role", ["related_customer_id"], :name => "related_customer_id"
  add_index "customer_role", ["relationship_type_id"], :name => "relationship_type_id"
  add_index "customer_role", ["role_group_id"], :name => "role_group_id"
  add_index "customer_role", ["role_type_id"], :name => "role_type_id"
  add_index "customer_role", ["related_role_group_id"], :name => "related_role_group_id"
  add_index "customer_role", ["related_role_type_id"], :name => "related_role_type_id"

  create_table "customer_status", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "customer_type", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string
  end

  create_table "deliv_status", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "edu_individual_customer", :force => true do |t|
    t.column "individual_customer_id", :integer, :references => nil
  end

  add_index "edu_individual_customer", ["individual_customer_id"], :name => "individual_customer_id"

  create_table "edu_org", :force => true do |t|
    t.column "org_id",                       :integer, :references => nil
    t.column "student_count",                :integer
    t.column "school_year_start_date",       :date
    t.column "school_year_end_date",         :date
    t.column "lowest_grade_code_primary",    :string,  :limit => 2
    t.column "highest_grade_code_primary",   :string,  :limit => 2
    t.column "lowest_grade_code_secondary",  :string,  :limit => 2
    t.column "highest_grade_code_secondary", :string,  :limit => 2
    t.column "high_age",                     :integer
    t.column "low_age",                      :integer
    t.column "nces_state_code",              :string,  :limit => 2
    t.column "nces_district_code",           :string,  :limit => 5
    t.column "nces_school_code",             :string,  :limit => 5
    t.column "nces_link_indicator",          :string,  :limit => 1
    t.column "book_volume_count",            :integer
  end

  add_index "edu_org", ["org_id"], :name => "org_id"

  create_table "email_address", :force => true do |t|
    t.column "email_address_type_id",      :integer, :references => nil
    t.column "deliv_status_id",            :integer, :references => nil
    t.column "email_address",              :string
    t.column "deliv_stats_date",           :datetime
    t.column "collection_method_id",       :integer, :references => nil
    t.column "preferred_email_indicator",  :string
    t.column "email_opt_in_status",        :string
    t.column "email_opt_in_date",          :datetime
    t.column "last_acknowledged_date",     :datetime
    t.column "enterprise_email_indicator", :string
    t.column "customer_id",                :integer, :references => nil
    t.column "email_src_sys_cust_id",      :string, :references => nil
    t.column "source_system_id",           :integer, :references => nil
  end

  add_index "email_address", ["email_address_type_id"], :name => "email_address_type_id"
  add_index "email_address", ["deliv_status_id"], :name => "deliv_status_id"
  add_index "email_address", ["collection_method_id"], :name => "collection_method_id"
  add_index "email_address", ["customer_id"], :name => "customer_id"
  add_index "email_address", ["source_system_id"], :name => "source_system_id"

  create_table "email_address_type", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
    t.column "text",        :string
  end

  create_table "entitlement", :force => true do |t|
    t.column "po_num",                 :string
    t.column "license_count",          :integer
    t.column "license_portability_id", :integer, :references => nil
    t.column "ordered",                :datetime
    t.column "shipped",                :datetime
    t.column "email_address",          :string
    t.column "first_name",             :string
    t.column "last_name",              :string
    t.column "entitlement_type_id",    :integer, :references => nil
    t.column "updated_at",             :datetime, :null => false
    t.column "created_at",             :datetime, :null => false
    t.column "root_org_id",            :integer, :references => nil
    t.column "license_duration_id",    :integer,  :null => false, :references => nil
    t.column "order_num",              :string
    t.column "originating_order_num",  :string
    t.column "shipment_num",           :string
    t.column "invoice_num",            :string
    t.column "master_order_num",       :string
    t.column "license_count_type_id",  :integer, :references => nil
    t.column "item_quantity",          :integer
    t.column "contact_ucn",            :string
    t.column "subscription_start",     :datetime
    t.column "subscription_end",       :datetime
    t.column "grace_period_id",        :integer, :references => nil
    t.column "item_id",                :integer,  :null => false, :references => nil
    t.column "tms_entitlementid",      :string,   :null => false
    t.column "sc_entitlement_type_id", :integer, :references => nil
  end

  add_index "entitlement", ["license_portability_id"], :name => "license_portability_id"
  add_index "entitlement", ["entitlement_type_id"], :name => "entitlement_type_id"
  add_index "entitlement", ["root_org_id"], :name => "root_org_id"
  add_index "entitlement", ["license_duration_id"], :name => "license_duration_id"
  add_index "entitlement", ["license_count_type_id"], :name => "license_count_type_id"
  add_index "entitlement", ["grace_period_id"], :name => "grace_period_id"
  add_index "entitlement", ["item_id"], :name => "item_id"
  add_index "entitlement", ["sc_entitlement_type_id"], :name => "sc_entitlement_type_id"

  create_table "entitlement_org", :force => true do |t|
    t.column "entitlement_id",          :integer, :null => false, :references => nil
    t.column "entitlement_org_type_id", :integer, :null => false, :references => nil
    t.column "name",                    :string
    t.column "ucn",                     :string
  end

  add_index "entitlement_org", ["entitlement_id"], :name => "entitlement_id"
  add_index "entitlement_org", ["entitlement_org_type_id"], :name => "entitlement_org_type_id"

  create_table "entitlement_org_type", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "entitlement_type", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "esb_message", :force => true do |t|
    t.column "correlation_id",    :string, :references => nil
    t.column "delivery_mode",     :integer
    t.column "message_id",        :string, :references => nil
    t.column "message_timestamp", :datetime
    t.column "message_text",      :text
    t.column "message_type",      :string
    t.column "message_class",     :string
    t.column "received",          :datetime
    t.column "parsed",            :datetime
    t.column "handled",           :datetime
    t.column "ignored",           :datetime
    t.column "held",              :datetime
    t.column "queue_name",        :string
  end

  create_table "esb_message_context", :force => true do |t|
    t.column "esb_message_id", :integer, :null => false, :references => nil
    t.column "name",           :string,  :null => false
    t.column "value",          :string
  end

  add_index "esb_message_context", ["esb_message_id"], :name => "esb_message_id"

  create_table "grace_period", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "item", :force => true do |t|
    t.column "item_num",            :string,                     :null => false
    t.column "description",         :string
    #t.column "product_id",          :integer,                    :null => false, :references => nil
    t.column "licenses",            :integer,                    :null => false
    t.column "item_type",           :string
    #t.column "default_for_product", :boolean, :default => false
  end

  #add_index "item", ["product_id"], :name => "product_id"

  create_table "license_count_type", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "license_duration", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "license_portability", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "org", :force => true do |t|
    t.column "customer_id",              :integer,                :null => false, :references => nil
    t.column "name",                     :string,  :limit => 100, :null => false
    t.column "alt_name",                 :string,  :limit => 30
    t.column "url",                      :string,  :limit => 75
    t.column "public_private_id",        :integer, :references => nil
    t.column "religious_affiliation_id", :integer, :references => nil
  end

  add_index "org", ["customer_id"], :name => "customer_id_2", :unique => true
  add_index "org", ["customer_id"], :name => "customer_id"
  add_index "org", ["public_private_id"], :name => "public_private_id"
  add_index "org", ["religious_affiliation_id"], :name => "religious_affiliation_id"

  create_table "permission", :force => true do |t|
    t.column "code",    :string,  :null => false
    t.column "name",    :string,  :null => false
    t.column "role_id", :integer, :null => false, :references => nil
  end

  create_table "product", :force => true do |t|
    t.column "description",      :string
    t.column "id_provider",      :string,  :null => false
    t.column "id_value",         :string,  :null => false
    t.column "product_group_id", :integer, :null => false, :references => nil
  end

  add_index "product", ["product_group_id"], :name => "product_group_id"

  create_table "product_group", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "product_version", :force => true do |t|
    t.column "product_id",  :integer, :null => false, :references => nil
    t.column "code",        :string,  :null => false
    t.column "description", :string
  end

  add_index "product_version", ["product_id"], :name => "product_id"

  create_table "public_private", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "relationship_category", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
    t.column "text",        :string
  end

  create_table "relationship_type", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
    t.column "text",        :string
  end

  create_table "religious_affiliation", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "response_code", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
    t.column "text",        :string
  end

  create_table "role", :force => true do |t|
    t.column "code", :string, :null => false
    t.column "name", :string, :null => false
  end

  create_table "role_group", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "role_type", :force => true do |t|
    t.column "code",        :string, :limit => 4
    t.column "description", :string, :limit => 75
  end

  create_table "salutation", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "sam_customer", :force => true do |t|
    t.column "root_org_id",          :integer,  :null => false, :references => nil
    t.column "auto_interval",        :integer
    t.column "update_conf",          :boolean
    t.column "install_time",         :string
    t.column "sc_registration_date", :datetime
  end

  add_index "sam_customer", ["root_org_id"], :name => "root_org_id"

  create_table "sam_server", :force => true do |t|
    t.column "root_org_id",                 :integer,                :null => false, :references => nil
    t.column "license_management_level",    :string
    t.column "name",                        :string
    t.column "created_at",                  :datetime
    t.column "updated_at",                  :datetime
    t.column "guid",                        :string,   :limit => 36, :null => false
    t.column "installation_code",           :string
    t.column "registration_entitlement_id", :integer, :references => nil
  end

  add_index "sam_server", ["guid"], :name => "index_sam_server_on_guid", :unique => true
  add_index "sam_server", ["root_org_id"], :name => "root_org_id"

  create_table "sam_server_address", :force => true do |t|
    t.column "sam_server_id",     :integer, :references => nil
    t.column "address_line_1",    :string
    t.column "address_line_2",    :string
    t.column "address_line_3",    :string
    t.column "city_name",         :string
    t.column "state_province_id", :integer, :references => nil
    t.column "postal_code",       :string
    t.column "country_id",        :integer, :references => nil
    t.column "org_name",          :string
    t.column "org_phone_number",  :string
    t.column "salutation_id",     :integer, :references => nil
    t.column "first_name",        :string
    t.column "middle_name",       :string
    t.column "last_name",         :string
    t.column "suffix_id",         :integer, :references => nil
    t.column "email_address",     :string
    t.column "phone_number",      :string
    t.column "updated_at",        :datetime, :null => false
    t.column "created_at",        :datetime, :null => false
  end

  add_index "sam_server_address", ["sam_server_id"], :name => "sam_server_id"
  add_index "sam_server_address", ["state_province_id"], :name => "state_province_id"
  add_index "sam_server_address", ["country_id"], :name => "country_id"
  add_index "sam_server_address", ["salutation_id"], :name => "salutation_id"
  add_index "sam_server_address", ["suffix_id"], :name => "suffix_id"

  create_table "sam_server_community_info", :force => true do |t|
    t.column "community_id",  :integer,  :null => false, :references => nil
    t.column "sam_server_id", :integer,  :null => false, :references => nil
    t.column "version",       :integer
    t.column "updated_at",    :datetime, :null => false
    t.column "created_at",    :datetime, :null => false
    t.column "enabled",       :boolean
  end

  add_index "sam_server_community_info", ["community_id"], :name => "community_id"
  add_index "sam_server_community_info", ["sam_server_id"], :name => "sam_server_id"

  create_table "sam_server_school_info", :force => true do |t|
    t.column "sam_server_id", :integer,  :null => false, :references => nil
    t.column "created_at",    :datetime, :null => false
    t.column "updated_at",    :datetime, :null => false
    t.column "sam_school_id", :string,   :null => false, :references => nil
    t.column "name",          :string,   :null => false
    t.column "student_count", :string
    t.column "school_number", :string
    t.column "title",         :string
    t.column "first_name",    :string
    t.column "middle_name",   :string
    t.column "last_name",     :string
    t.column "address1",      :string
    t.column "address2",      :string
    t.column "address3",      :string
    t.column "city",          :string
    t.column "state",         :string
    t.column "country",       :string
    t.column "postal_code",   :string
    t.column "phone",         :string
    t.column "email",         :string
    t.column "org_id",        :integer, :references => nil
  end

  add_index "sam_server_school_info", ["org_id"], :name => "org_id", :unique => true
  add_index "sam_server_school_info", ["sam_server_id"], :name => "sam_server_id"

  create_table "sam_server_subcommunity_info", :force => true do |t|
    t.column "sam_server_community_info_id", :integer,                :null => false, :references => nil
    t.column "subcommunity_id",              :integer,                :null => false, :references => nil
    t.column "licensed_seats",               :integer, :default => 0
    t.column "used_seats",                   :integer, :default => 0
  end

  add_index "sam_server_subcommunity_info", ["sam_server_community_info_id"], :name => "sam_server_community_info_id"
  add_index "sam_server_subcommunity_info", ["subcommunity_id"], :name => "subcommunity_id"

  create_table "sc_entitlement_type", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "seat", :force => true do |t|
    t.column "entitlement_id", :integer, :references => nil
    t.column "sam_server_id",  :integer, :references => nil
    t.column "seat_status_id", :integer,  :null => false, :references => nil
    t.column "orig_seat_id",   :integer, :references => nil
    t.column "updated_at",     :datetime, :null => false
    t.column "created_at",     :datetime, :null => false
  end

  add_index "seat", ["entitlement_id"], :name => "entitlement_id"
  add_index "seat", ["sam_server_id"], :name => "sam_server_id"
  add_index "seat", ["seat_status_id"], :name => "seat_status_id"
  add_index "seat", ["orig_seat_id"], :name => "orig_seat_id"

  create_table "seat_status", :force => true do |t|
    t.column "code",        :string
    t.column "description", :string
  end

  create_table "source_system", :force => true do |t|
    t.column "code",        :string, :limit => 10
    t.column "description", :string, :limit => 75
  end

  create_table "state_province", :force => true do |t|
    t.column "code",       :string,  :limit => 3
    t.column "country_id", :integer, :references => nil
    t.column "name",       :string,  :limit => 75
  end

  add_index "state_province", ["country_id"], :name => "country_id"

  create_table "subcommunity", :force => true do |t|
    t.column "name",                        :string,  :limit => 128
    t.column "code",                        :string
    t.column "license_seed_code",           :string
    t.column "community_id",                :integer, :references => nil
    t.column "product_id",                  :integer, :references => nil
    t.column "suppress_entitlement_update", :boolean,                :default => false
  end

  add_index "subcommunity", ["community_id"], :name => "community_id"
  add_index "subcommunity", ["product_id"], :name => "product_id"

  create_table "suffix", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  create_table "telephone", :force => true do |t|
    t.column "customer_id",                    :integer, :references => nil
    t.column "telephone_type_id",              :integer, :references => nil
    t.column "telephone_number",               :string
    t.column "telephone_extension_number",     :string,   :limit => 15
    t.column "effective_date",                 :datetime
    t.column "fax_authorization_indicator",    :string
    t.column "fax_authorization_last_name",    :string
    t.column "fax_authorization_first_name",   :string
    t.column "fax_authorization_job_title",    :string
    t.column "fax_authorization_date",         :datetime
    t.column "fax_authorization_text",         :string
    t.column "domestic_indicator",             :string
    t.column "last_contact_date",              :datetime
    t.column "response_code_id",               :integer, :references => nil
    t.column "state_dncl_indicator",           :string
    t.column "state_dncl_update_date",         :datetime
    t.column "federal_dncl_indicator",         :string
    t.column "federal_dncl_update_date",       :datetime
    t.column "collection_method_id",           :integer, :references => nil
    t.column "last_acknowledged_date",         :datetime
    t.column "enterprise_telephone_indicator", :string
  end

  add_index "telephone", ["customer_id"], :name => "customer_id"
  add_index "telephone", ["telephone_type_id"], :name => "telephone_type_id"
  add_index "telephone", ["response_code_id"], :name => "response_code_id"
  add_index "telephone", ["collection_method_id"], :name => "collection_method_id"

  create_table "telephone_type", :force => true do |t|
    t.column "code",                              :string
    t.column "customer_classification_indicator", :string
    t.column "description",                       :string
    t.column "text",                              :string
  end

  create_table "user_permission", :force => true do |t|
    t.column "user_id",       :integer, :null => false, :references => nil
    t.column "permission_id", :integer, :null => false, :references => nil
  end

  add_index "user_permission", ["user_id"], :name => "user_id"
  add_index "user_permission", ["permission_id"], :name => "permission_id"

  create_table "users", :force => true do |t|
    t.column "login",                     :string
    t.column "email",                     :string
    t.column "crypted_password",          :string,   :limit => 40
    t.column "salt",                      :string,   :limit => 40
    t.column "created_at",                :datetime
    t.column "updated_at",                :datetime
    t.column "remember_token",            :string
    t.column "remember_token_expires_at", :datetime
    t.column "first_name",                :string
    t.column "last_name",                 :string
    t.column "org_id",                    :integer,                :null => false, :references => nil
  end

  add_index "users", ["org_id"], :name => "org_id"

  create_table "usps_record_type", :force => true do |t|
    t.column "code",        :string, :limit => 3
    t.column "description", :string, :limit => 75
  end

  
    add_foreign_key "agent", ["sam_server_id"], "sam_server", ["id"]

  add_foreign_key "agent_community", ["agent_id"], "agent", ["id"]

  add_foreign_key "agent_plugin", ["agent_id"], "agent", ["id"]

  add_foreign_key "alert", ["target_role_id"], "role", ["id"]

  add_foreign_key "conversation_command", ["conversation_state_instance_id"], "conversation_state_instance", ["id"]

  add_foreign_key "conversation_command_error", ["conversation_command_id"], "conversation_command", ["id"]

  add_foreign_key "conversation_command_property", ["conversation_command_id"], "conversation_command", ["id"]

  add_foreign_key "conversation_current_state", ["conversation_instance_id"], "conversation_instance", ["id"]
  add_foreign_key "conversation_current_state", ["conversation_state_instance_id"], "conversation_state_instance", ["id"]

  add_foreign_key "conversation_instance", ["result_type_id"], "conversation_result_type", ["id"]
  add_foreign_key "conversation_instance", ["agent_id"], "agent", ["id"]

  add_foreign_key "conversation_instance_variable", ["conversation_instance_id"], "conversation_instance", ["id"]

  add_foreign_key "conversation_state_instance", ["conversation_instance_id"], "conversation_instance", ["id"]

  add_foreign_key "customer", ["customer_status_id"], "customer_status", ["id"]
  add_foreign_key "customer", ["customer_group_id"], "customer_group", ["id"]
  add_foreign_key "customer", ["customer_type_id"], "customer_type", ["id"]

  add_foreign_key "customer_address", ["country_id"], "country", ["id"]
  add_foreign_key "customer_address", ["customer_id"], "customer", ["id"]
  add_foreign_key "customer_address", ["address_type_id"], "address_type", ["id"]
  add_foreign_key "customer_address", ["usps_record_type_id"], "usps_record_type", ["id"]
  add_foreign_key "customer_address", ["state_province_id"], "state_province", ["id"]

  add_foreign_key "customer_relationship", ["relationship_category_id"], "relationship_category", ["id"]
  add_foreign_key "customer_relationship", ["customer_id"], "customer", ["id"]
  add_foreign_key "customer_relationship", ["related_customer_id"], "customer", ["id"]
  add_foreign_key "customer_relationship", ["relationship_type_id"], "relationship_type", ["id"]

  add_foreign_key "customer_role", ["related_role_group_id"], "role_group", ["id"]
  add_foreign_key "customer_role", ["related_role_type_id"], "role_group", ["id"]
  add_foreign_key "customer_role", ["customer_id"], "customer", ["id"]
  add_foreign_key "customer_role", ["related_customer_id"], "customer", ["id"]
  add_foreign_key "customer_role", ["relationship_type_id"], "relationship_type", ["id"]
  add_foreign_key "customer_role", ["role_group_id"], "role_group", ["id"]
  add_foreign_key "customer_role", ["role_type_id"], "role_type", ["id"]

  add_foreign_key "edu_org", ["org_id"], "org", ["id"]

  add_foreign_key "email_address", ["source_system_id"], "source_system", ["id"]
  add_foreign_key "email_address", ["collection_method_id"], "collection_method", ["id"]
  add_foreign_key "email_address", ["email_address_type_id"], "email_address_type", ["id"]
  add_foreign_key "email_address", ["deliv_status_id"], "deliv_status", ["id"]
  add_foreign_key "email_address", ["customer_id"], "customer", ["id"]

  add_foreign_key "entitlement", ["sc_entitlement_type_id"], "sc_entitlement_type", ["id"]
  add_foreign_key "entitlement", ["item_id"], "item", ["id"]
  add_foreign_key "entitlement", ["license_portability_id"], "license_portability", ["id"]
  add_foreign_key "entitlement", ["entitlement_type_id"], "entitlement_type", ["id"]
  add_foreign_key "entitlement", ["root_org_id"], "org", ["id"]
  add_foreign_key "entitlement", ["license_duration_id"], "license_duration", ["id"]
  add_foreign_key "entitlement", ["license_count_type_id"], "license_count_type", ["id"]
  add_foreign_key "entitlement", ["grace_period_id"], "grace_period", ["id"]

  add_foreign_key "entitlement_org", ["entitlement_org_type_id"], "entitlement_org_type", ["id"]
  add_foreign_key "entitlement_org", ["entitlement_id"], "entitlement", ["id"]

  add_foreign_key "esb_message_context", ["esb_message_id"], "esb_message", ["id"]

  #add_foreign_key "item", ["product_id"], "product", ["id"]

  add_foreign_key "org", ["religious_affiliation_id"], "religious_affiliation", ["id"]
  add_foreign_key "org", ["customer_id"], "customer", ["id"]
  add_foreign_key "org", ["public_private_id"], "public_private", ["id"]

  add_foreign_key "product", ["product_group_id"], "product_group", ["id"]

  add_foreign_key "product_version", ["product_id"], "product", ["id"]

  add_foreign_key "sam_customer", ["root_org_id"], "org", ["id"]

  add_foreign_key "sam_server", ["root_org_id"], "org", ["id"]

  add_foreign_key "sam_server_address", ["country_id"], "country", ["id"]
  add_foreign_key "sam_server_address", ["sam_server_id"], "sam_server", ["id"]
  add_foreign_key "sam_server_address", ["state_province_id"], "state_province", ["id"]
  add_foreign_key "sam_server_address", ["salutation_id"], "salutation", ["id"]
  add_foreign_key "sam_server_address", ["suffix_id"], "suffix", ["id"]

  add_foreign_key "sam_server_community_info", ["community_id"], "community", ["id"]
  add_foreign_key "sam_server_community_info", ["sam_server_id"], "sam_server", ["id"]

  add_foreign_key "sam_server_school_info", ["sam_server_id"], "sam_server", ["id"]

  add_foreign_key "sam_server_subcommunity_info", ["sam_server_community_info_id"], "sam_server_community_info", ["id"]
  add_foreign_key "sam_server_subcommunity_info", ["subcommunity_id"], "subcommunity", ["id"]

  add_foreign_key "seat", ["entitlement_id"], "entitlement", ["id"]
  add_foreign_key "seat", ["sam_server_id"], "sam_server", ["id"]
  add_foreign_key "seat", ["seat_status_id"], "seat_status", ["id"]
  add_foreign_key "seat", ["orig_seat_id"], "seat", ["id"]

  add_foreign_key "state_province", ["country_id"], "country", ["id"]

  add_foreign_key "subcommunity", ["community_id"], "community", ["id"]
  add_foreign_key "subcommunity", ["community_id"], "community", ["id"]
  add_foreign_key "subcommunity", ["product_id"], "product", ["id"]

  add_foreign_key "telephone", ["collection_method_id"], "collection_method", ["id"]
  add_foreign_key "telephone", ["customer_id"], "customer", ["id"]
  add_foreign_key "telephone", ["telephone_type_id"], "telephone_type", ["id"]
  add_foreign_key "telephone", ["response_code_id"], "response_code", ["id"]

  add_foreign_key "user_permission", ["user_id"], "users", ["id"]
  add_foreign_key "user_permission", ["permission_id"], "permission", ["id"]

  add_foreign_key "users", ["org_id"], "org", ["id"]

  end
  
  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
