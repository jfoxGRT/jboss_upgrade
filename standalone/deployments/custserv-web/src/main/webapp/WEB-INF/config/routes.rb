ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.
  map.resources :processes, :collection => {:search => :get, :export_processes_search_to_csv => :get}
  map.resources :agents do |agents|
    agents.resources :conversations, :controller => :agent_conversations do |conversations|
      conversations.resources :conversation_states
      conversations.resources :alerts, :controller => :conversation_alerts
    end
  end

  map.resources :conv_export_master_batches, :collection => {:open_master_batch_sam_customers => :get}
  map.resources :conv_export_sub_batches, :collection => {:export_conv_export_sub_batches_to_csv => :get}

  map.resources :entitlement_assignment_suppressions
  map.resources :saplings,
    :collection => {:index_repository => :get, :index_upload => :get, :index_batch_targeting => :get, :index_custom_targeting => :get, :refresh_eligibility => :get, :publish_saplng => :get, :select_product => :get, :select_customer => :get, :select_server => :get}
  map.resources :doc_items, 
    :collection => {:index_dashboard => :get, :index_manage => :get, :index_faqs_cs => :get, :index_faqs_fe => :get, :index_faqs_e4e => :get, :index_faqs_all => :get}
  map.resources :doc_locations
  map.resources :doc_labels

  map.resources :states, :controller => :state_provinces do |states|
    states.resources :sam_customers  
  end
  
  map.resources :lm_conversion_blacklists
  
  map.resources :sam_customers, :member => {:add_favorite => :put, :remove_favorite => :delete, :merge => :put, :merge_from => :get, :transfer_resources => :get, :use_customer_app_for => :get}, 
        :collection => {:states => :get, :search => :get, :search_by_name_or_id => :get, :export_sam_customers_to_csv => :get, :edit_license_manager_defaults => :get } do |sam_customers|
    sam_customers.resources :managers, :member => {:reset => :put, :activate => :put, :deactivate => :put}, :controller => :sam_customer_managers
    sam_customers.resources :sam_servers do |sam_servers|
        sam_servers.resources :seat_activities, :controller => :sam_server_seat_activities
    end
    sam_customers.resources :subcommunities, :controller => :sam_customer_subcommunities, 
        :collection => {:license_types_for => :get, :license_conversion_policy_for => :get, :global_allocation_policy_for => :get, :audit_license_counts => :post, :licensing_audit_trail_for => :get}, 
        :member => {:seat_pool_history => :get, :entitlement_event_history => :get, :server_count_history => :get} do |subcommunities|
      subcommunities.resources :seat_pools, :member => {:lcd_autoresolve_audit => :get}
      subcommunities.resources :entitlements
    end
    sam_customers.resources :seat_activities, :controller => :sam_customer_seat_activities do |seat_activities|
      seat_activities.resources :conversations, :controller => :seat_activity_conversations
    end
    sam_customers.resources :entitlement_known_destinations
    sam_customers.resources :notification_types, :controller => :sam_customer_alerts do |alerts|
      alerts.resources :notifications, :controller => :sam_customer_alert_instances
    end
    sam_customers.resources :audits
    sam_customers.resources :auth_users, :collection => {:export_auth_users_customer_page_to_csv => :get}
    sam_customers.resources :users
    sam_customers.resources :entitlements, :collection => {:operate_on => :post}
    sam_customers.resources :metrics
    sam_customers.resources :schools, :controller => :sam_customer_schools
    sam_customers.resources :hosting_rules, :controller => :sam_customer_hosting_rules
  end
  
  map.resources :notifications, :controller => :alert_instances, :collection => {:group_by_server => :get, :group_by_event_type => :get}

  map.resources :async_activities, :controller => :async_activities

  map.resources :sam_servers, :member => {:request_agent_connect_now => :get, :show_deactivate => :get, :show_flag_for_transition => :get, :show_remediate => :get, :remediate => :post, :find_esb_messages_for => :get, :internal_messages_for => :get}, 
                :collection => {:operate_on => :post, :operate_on => :get, :search => :get, :export_sam_servers_to_csv => :get, :show_move_history_for => :get} do |sam_servers|
    sam_servers.resources :sam_server_community_infos, :name_prefix => nil, :controller => :sam_server_community_infos
#    sam_servers.resources :sam_server_subcommunity_infos, :name_prefix => nil, :controller => :sam_server_subcommunity_infos
    sam_servers.resources :sam_server_school_infos, :controller => :sam_server_school_infos
    sam_servers.resources :sam_server_users, :controller => :sam_server_users
    sam_servers.resources :report_requests, :controller => :sam_server_report_requests
  end
  
  map.resources :sam_server_school_infos do |sam_server_school_infos|
    sam_server_school_infos.resources :sam_server_school_enrollments, :name_prefix => nil, :controller => :sam_server_school_enrollments
  end
  
  map.resources :notification_types, :controller => :alerts do |alerts|
    alerts.resources :notifications, :collection => {:group_by_sam_customer => :get}, :controller => :alert_instances
  end
  
  map.resources :audits
  map.resources :unmatched_schools
  map.resources :seat_activities
  map.resources :entitlements, :collection => {:find => :get, :search => :get, :search_loading => :get, :export_entitlements_to_csv => :get, 
    :export_license_entitlements_to_csv => :get, :export_service_entitlements_to_csv => :get, :export_all_entitlements_to_csv => :get, :export_customer_entitlements_to_csv => :get, :history_for => :get}, 
    :member => {:order_set_for => :get}
  map.resources :conversations
  map.resources :users 
  map.resources :email_messages, :collection => {:search => :get, :export_email_search_to_csv => :get}
  map.resources :auth_users, :collection => {:status_for => :get, :profile_status_for => :get, :search => :get, :export_auth_users_search_to_csv => :get}
  
  # CSI routes
  # unfortunately, because our design is now using jQuery, we cannot be RESTful in these following actions :( ..  all the 'member' routes ought to be posts, not gets
  map.resources :orgs, :collection => {:search => :get, :dialog_popup => :get, :dialog_show_org_details => :get, :dialog_show_children => :get, :dialog_get_children => :get, :dialog_get_parent => :get, :export_orgs_to_csv => :get}, 
						:member => {:show_summary_info_for => :get, :search_summary_info_for => :get, :change_selected => :get, :add_to_task => :get}
  
  # ESB Messaging
  map.resources :esb_messages, :collection => {:search => :get}
  
  TASKS_PREFIX = "/tasks"
  
  map.resources :unassigned_orders, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  map.resources :super_admin_requests, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  map.resources :license_count_discrepancies, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  map.resources :license_count_integrity_problems, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  map.resources :sc_licensing_activations, :member => {:sync_steps_status_for => :put}, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  map.resources :pending_license_count_changes, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  map.resources :pending_entitlements, :member => {:get_org_info => :get}, :collection => {:assigned => :get, :unassigned => :get}, :path_prefix => TASKS_PREFIX
  
  # Tasks
  map.resources :tasks, :collection => {:get_task_details => :get, :user => :get, :assigned => :get, :unassigned => :get, :group => :get, :search => :get, :export_tasks_to_csv => :get}, :member => {:assign => :put, :unassign => :get, :reopen => :put, :add_comment_for => :post} do |tasks|
    tasks.resources :license_count_discrepancies, :controller => :license_count_discrepancy_task
  end
  
  # TwinzMQ Controllers

  map.resources :sam_central_messages, :collection => {:stats => :get} 
  map.resources :sam_central_message_alts
  map.resources :sam_central_message_auths
  map.resources :sam_central_message_commanders
  map.resources :sam_central_message_core_audits
  map.resources :sam_central_message_core_emails
  map.resources :sam_central_message_core_processors
  map.resources :sam_central_message_messagings
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => 'account', :action => 'login'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  # Uncomment this line when it's time to use the javascript controller
  #map.connect ':controller/:action.:format'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  
  map.resources :banner_message
  
  map.resources :moratorium
  
  map.resources :auth_zones
  
end
