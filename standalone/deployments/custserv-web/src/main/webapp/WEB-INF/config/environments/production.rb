# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false

SEAT_MANAGER_URL = 'http://localhost:8080/core/services/SeatManager'
ENTITLEMENT_MANAGER_URL = 'http://localhost:8080/core/services/EntitlementManager'
USER_MANAGER_URL = 'http://localhost:8080/core/services/UserManager'
SAM_CUSTOMER_MANAGER_URL = 'http://localhost:8080/core/services/SamCustomerManager'
