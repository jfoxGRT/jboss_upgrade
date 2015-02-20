module SamServersHelper
  
  def translate_status_text(status_code)
    case (status_code)
      when "t" then "Transitioning"
      when "a" then "Active"
      when "i" then "Inactive"
    end
  end
  
  def translate_command_id_text(command_id)
    case (command_id)
      when "noop" then "Connecting.."
      when "getschoolinfo" then "Getting schools.."
      when "addslmsmessage" then "Writing SAM Client message.."
      when "assignlicense" then "Reallocating licenses.."
      when "clientupdate" then "Updating SAM Client.."
      when "getsaplinginfo" then "Getting product information.."
      when "getstats" then "Getting subcommander stats.."
      when "getteachers" then "Getting teachers.."
      when "samservercomponentupdate" then "Updating SAM Server.."
      when "saplingupdate" then "Updating product information.."
      when "selfupdate" then "Updating agent.."
      when "setcredentials" then "Authenticating.."
      when "setsamallocationlevel" then "Updating license allocation mode.."
      when "setseatcapforproduct" then "Updating school license cap.."
      when "usesamcentrallicensing" then "Activating for License Manager.."
      else "Connecting.."
    end
  end
  
end
