module UtilitiesHelper
  
  def translate_process_code(code)
    case code
    when "SSD" then "Server Deactivation"
    when "FOG" then "Fake Order Generation"
    when "SSM" then "Server Move"
    when "EM" then "Entitlement Move"
    else "Unknown"
    end
  end
  
end
