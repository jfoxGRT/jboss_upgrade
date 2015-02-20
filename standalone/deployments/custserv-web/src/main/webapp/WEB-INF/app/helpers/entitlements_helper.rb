module EntitlementsHelper
  def translate_virtual_reason_code(reason_code)
    case reason_code
      when "ALCDTR" then "Automatic Discrepancy Resolution"
      when "UGPE" then "Unregistered Server Pool Empty"
      when "LCDTR" then "LCD Task Resolution"
      when "LCIPTR" then "LCIP Task Resolution"
      when "MAL" then "Manual License Adjustment"
      when "MRL" then "Manual License Adjustment"
      when "NCS" then "New Clone Server"
      when "RLCDT" then "Discrepancy Resolution"
      when "SD" then "Server Deactivation"
      when "ST" then "Server Transfer"
      else "Unknown"
    end
  end
end
