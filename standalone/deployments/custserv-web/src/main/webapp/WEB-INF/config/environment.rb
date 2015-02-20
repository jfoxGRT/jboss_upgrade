# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2'
PAGINATION_ROWS_PER_PAGE = 17

APP_CONTEXT_PATH = "/custserv"

ADMIN_ONLY_IMAGE = "red-square.GIF"


# SAMC Terms

SAM_CUSTOMER_TERM = "SAM Customer"
CUSTOMER_STATISTICS_TERM = "Customer Usage Statistics"
CUSTOMER_USERS_TERM = "Customer Admins"
SCHOLASTIC_REPORTS_TERM = "C/S Rep Activity"

LICENSE_MANAGER_TERM = "License Manager"
UPDATE_MANAGER_TERM = "Server Update Manager"
AUTH_MANAGER_TERM = "Auth Manager"
SCHOLASTIC_INDEX_TERM = "SAMC Index"



DATE_FORM = "%m/%d/%y  (%I:%M:%S %p)"
JUST_DATE_FORM = "%m/%d/%y"

SAM_CUSTOMER_SINGULAR_CONTROLLER_NAME = "sam_customer"

ALERTS_CODE = "A"
CS_REP_ACTIVITY_CODE = "CSRA"

AUTH_USERS_CODE = "AU"
CUSTOMER_ADMINS_CODE = "CA"
CUSTOMER_USAGE_STATISTICS_CODE = "CUS"
ENTITLEMENTS_CODE = "E"
LICENSE_COUNTS_CODE = "LC"
SAM_SERVERS_CODE = "SS"
SCHOOLS_ON_SAM_SERVERS_CODE = "SISS"
SEAT_ACTIVITY_CODE = "SA"
PRODUCT_TERM = "Program"
HOSTING_RULES_CODE = "HRS"

SAM_CUSTOMER_SITE_AREAS = [
  {:name => "Auth Users", :controller_name => "auth_users", :code => AUTH_USERS_CODE, :user_type => 's'},
  {:name => "Customer Admins", :controller_name => "users", :code => CUSTOMER_ADMINS_CODE, :user_type => 's'},
  {:name => "Entitlements", :controller_name => "entitlements", :code => ENTITLEMENTS_CODE, :user_type => 's'},
  {:name => "License Counts", :controller_name => "subcommunities", :code => LICENSE_COUNTS_CODE, :user_type => 's'},
  {:name => "Notifications", :controller_name => "notification_types", :code => ALERTS_CODE, :user_type => 's'},
  {:name => "SAM Servers", :controller_name => "sam_servers", :code => SAM_SERVERS_CODE, :user_type => 's'},
  {:name => "Scholastic Activity", :controller_name => "audits", :code => CS_REP_ACTIVITY_CODE, :user_type => 's'},
  {:name => "Schools on Servers", :controller_name => "schools", :code => SCHOOLS_ON_SAM_SERVERS_CODE, :user_type => 's'},
  {:name => "Seat Activity", :controller_name => "seat_activities", :code => SEAT_ACTIVITY_CODE, :user_type => 's'},
  {:name => "Hosting Rules Activity", :controller_name => "hosting_rules", :code => HOSTING_RULES_CODE, :user_type => 's'}
]

SAMC_PROCESS_SAM_SERVER_MOVE = "SSM"
SAMC_PROCESS_SAM_SERVER_DEACTIVATION = "SSD"
SAMC_PROCESS_ENTITLEMENT_MOVE = "EM"
SAMC_PROCESS_FAKE_ORDER_GENERATOR = "FOG"

SAMC_PROCESSORS = Hash.new
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_INIT_0"] = "Moving servers"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_MASR_0"] = "Sending updated server registration(s) to TMS"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_CPSR_0"] = "Updating license counts and Super Admin requests"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_AE_1"] = "Updating Authentication Managers"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_ASSU_0"] = "Updating SAM Server user statuses"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_CAMEE_1"] = "Compiling emails for SAM Server users"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_MASC_1"] = "Sending updated license counts to TMS"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_MASR_1"] = "Sending new server registration(s) to TMS"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_MAEI_1"] = "Sending virtual entitlements to TMS"
#SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_MOVE}_MAE_1"] = "Sending interaction(s) to TMS"

SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_DEACTIVATION}_INIT_0"] = "Deactivating servers"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_DEACTIVATION}_MASR_0"] = "Sending server deactivation(s) to TMS"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_DEACTIVATION}_CPSR_0"] = "Updating license counts and Super Admin requests"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_DEACTIVATION}_ASSU_0"] = "Updating SAM Server user statuses"
SAMC_PROCESSORS["#{SAMC_PROCESS_SAM_SERVER_DEACTIVATION}_CAMEE_1"] = "Compiling emails for SAM Server users"

SAMC_PROCESSORS["#{SAMC_PROCESS_ENTITLEMENT_MOVE}_INIT_0"] = "Moving entitlements"
SAMC_PROCESSORS["#{SAMC_PROCESS_ENTITLEMENT_MOVE}_MAEI_0"] = "Sending entitlement assignments to TMS"
SAMC_PROCESSORS["#{SAMC_PROCESS_ENTITLEMENT_MOVE}_AE_0"] = "Verifying Auth Manager statuses"

SAMC_PROCESSORS["#{SAMC_PROCESS_FAKE_ORDER_GENERATOR}_INIT_0"] = "Preparing necessary entitlements"
SAMC_PROCESSORS["#{SAMC_PROCESS_FAKE_ORDER_GENERATOR}_MADE_0"] = "Simulating send from TMS"


TIME_BY_HALF_HOURS = [
  ["12:00 AM", "00:00:00"],
  ["12:30 AM", "00:30:00"],
  ["1:00 AM", "01:00:00"],
  ["1:30 AM", "01:30:00"],
  ["2:00 AM", "02:00:00"],
  ["2:30 AM", "02:30:00"],
  ["3:00 AM", "03:00:00"],
  ["3:30 AM", "03:30:00"],
  ["4:00 AM", "04:00:00"],
  ["4:30 AM", "04:30:00"],
  ["5:00 AM", "05:00:00"],
  ["5:30 AM", "05:30:00"],
  ["6:00 AM", "06:00:00"],
  ["6:30 AM", "06:30:00"],
  ["7:00 AM", "07:00:00"],
  ["7:30 AM", "07:30:00"],
  ["8:00 AM", "08:00:00"],
  ["8:30 AM", "08:30:00"],
  ["9:00 AM", "09:00:00"],
  ["9:30 AM", "09:30:00"],
  ["10:00 AM", "10:00:00"],
  ["10:30 AM", "10:30:00"],
  ["11:00 AM", "11:00:00"],
  ["11:30 AM", "11:30:00"],
  ["12:00 PM", "12:00:00"],
  ["12:30 PM", "12:30:00"],
  ["1:00 PM", "13:00:00"],
  ["1:30 PM", "13:30:00"],
  ["2:00 PM", "14:00:00"],
  ["2:30 PM", "14:30:00"],
  ["3:00 PM", "15:00:00"],
  ["3:30 PM", "15:30:00"],
  ["4:00 PM", "16:00:00"],
  ["4:30 PM", "16:30:00"],
  ["5:00 PM", "17:00:00"],
  ["5:30 PM", "17:30:00"],
  ["6:00 PM", "18:00:00"],
  ["6:30 PM", "18:30:00"],
  ["7:00 PM", "19:00:00"],
  ["7:30 PM", "19:30:00"],
  ["8:00 PM", "20:00:00"],
  ["8:30 PM", "20:30:00"],
  ["9:00 PM", "21:00:00"],
  ["9:30 PM", "21:30:00"],
  ["10:00 PM", "22:00:00"],
  ["10:30 PM", "22:30:00"],
  ["11:00 PM", "23:00:00"],
  ["11:30 PM", "23:30:00"]  
]

TASK_CONTROLLER_LIST = [
	["PLCC", "pending_license_count_changes", "Pending License Count Changes"],
	["LCD", "license_count_discrepancies", "License Count Discrepancies"],
	["NSA", "super_admin_requests", "Super Admin Requests"],
	["SCLA", "sc_licensing_activations", "SC-Licensing Activations"],
	["UE", "pending_entitlements", "Pending Entitlements"],
	["LCIP", "license_count_integrity_problems", "License Count Integrity Problems"]
]

MAX_TASKS_DISPLAYED = 50

# Online Report Max's
MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_DEFAULT = 2000
MAX_ONLINE_REPORT_ROWS_TO_DISPLAY_ALERTS = 1000


# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#if defined?(JRUBY_VERSION)
  # hack to fix jruby-rack's incompatibility with rails edge
#  module ActionController
#    module Session
#      class JavaServletStore
#        def initialize(app, options={}); end
#        def call(env); end
#      end
#    end
#  end
#end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.gem 'mislav-will_paginate', :version => '~> 2.3.8', :lib => 'will_paginate', 
    :source => 'http://gems.github.com'

end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
  gem 'rails_sql_views'
  #require 'rails_sql_views'

# Finder stuff 
FINDER_LIMIT = 1000 # note that WebAPI defines its own limit as well
AUTH_USER_FINDER_RESULTS_FILENAME = 'Auth User Finder Results'
CUSTOMER_FINDER_RESULTS_FILENAME = 'SAM Customer Finder Results'
EMAIL_FINDER_RESULTS_FILENAME = 'Email Finder Results'
ENTITLEMENT_FINDER_RESULTS_FILENAME = 'Entitlement Finder Results'
ORG_FINDER_RESULTS_FILENAME = 'Org Finder Results'
PROCESS_FINDER_RESULTS_FILENAME = 'Process Finder Results'
REPORT_FINDER_RESULTS_FILENAME = 'Report Request Finder Results'
SERVER_FINDER_RESULTS_FILENAME = 'SAM Server Finder Results'
TASK_FINDER_RESULTS_FILENAME = 'Task Finder Results'

# jQuery Datatables stuff
DATATABLES_SWF_PATH = "#{APP_CONTEXT_PATH}/javascripts/jquery/tabletools/media/swf/"
