module SuperAdminRequestsHelper
  
  def translate_scholastic_index(scholastic_index)
    puts("the scholastic index is #{scholastic_index}")
    case scholastic_index
      when "5" then "Largest Index #{SAM_CUSTOMER_TERM}s"
      when "4" then "Large Index #{SAM_CUSTOMER_TERM}s"
      when "3" then "Medium Index #{SAM_CUSTOMER_TERM}s"
      when "2" then "Small Index #{SAM_CUSTOMER_TERM}s"
      when "1" then "Smallest Index #{SAM_CUSTOMER_TERM}s"
    end
  end
  
end
