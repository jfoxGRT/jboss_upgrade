module SamCustomerSubcommunitiesHelper  
  
  def translate_conversion_audit_reason(reason_code)
    case reason_code
      when 0 then "New Conversion License Pool"
      when 1 then "New Conversion Entitlement"
      when 2 then "Entitlement License Count Change"
      when 3 then "Manual Conversion"
      when 4 then "PLCC Task Resolution"
      else "Unknown"
    end
  end
  
end
