require 'core_services/bridging_service'

# All Web Services calls for CustServ should be handled by through interface.

class CustServServicesHandler
  include CoreServices

  ROUTES = {
            "agents_web_services"                              => "/api/agents/",
            "create_edit_delete_sam_customer"                  => "/api/sam_customers/",
            "create_edit_delete_sam_server"                    => "/api/sam_servers/",
            "create_edit_delete_user"                          => "/api/users/",
            "entitlement_web_services"                        => "/api/entitlements/",
			      "utilities_web_services"                           => "/api/utilities",
			"email_finder_web_services"							=> "/api/finder/email/",
			"sam_central_message_service"           => "/api/sam_central_messages",
			"sam_customer_finder_web_services"					=> "/api/finder/sam_customer/",
			"entitlement_finder_web_services"					=> "/api/finder/entitlement/",
			"sam_server_finder_web_services"                    => "/api/finder/sam_server/",
			"task_finder_web_services"							=> "/api/finder/task/",
			"process_finder_web_services"						=> "/api/finder/process/",
			"org_finder_web_services"							=> "/api/finder/org/",
			"authuser_finder_web_services"						=> "/api/finder/authuser/",
			"request_report_finder_web_services"				=> "/api/finder/request_report/",
			"clones_review_report_web_services"					=> "/api/report/clone_review/",
            "manual_batch_override_web_services"                => "/api/manual_batch_override",
  }

  USER_CREDENTIALS = {
            "username" => "custserv-web",
            "password" => "c2ee8df9-9ef6-4a99-ad1b-17ac852fca8a"
  }
end
