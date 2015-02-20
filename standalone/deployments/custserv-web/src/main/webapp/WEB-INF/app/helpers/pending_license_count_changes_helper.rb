module PendingLicenseCountChangesHelper

	def translate_reason_code(code)
		case code
	    when "CSA" then "Seat Activity Cancellation"
			when "LCF" then "Licensing Conversation Failure"
			when "LMC" then "License Manager Conversion"
			when "LSS" then "License Subscription Start"
			when "LSE" then "License Subscription End"
			when "D" then "Decommission"
			when "ELCC" then "Entitlement License Count Change"
			when "ESC" then "Entitlement Subscription Change"
			when "MCZ" then "Make Count Zero"
			when "SIPC" then "Server Initial License Manager Count"
			when "NAR" then "New Agent Report"
			when "NP" then "New Pool"
			when "NVE" then "New Virtual Entitlement"
			when "RLM" then "Reset License Manager"
			when "RLCDT" then "Resolve License Count Discrepancy Task"
			when "RLCIPT" then "Resolve License Count Integrity Problem Task"
			when "SD" then "Server Deactivation"
			when "ST" then "Server Move"
			when "TN" then "TMS Notify"
			when "0" then "New Conversion License Pool"
      when "1" then "New Conversion Entitlement"
      when "2" then "Entitlement License Count Change"
      when "3" then "Manual Conversion"
      when "4" then "PLCC Task Resolution"
			else "Unknown"
		end
	end

end
