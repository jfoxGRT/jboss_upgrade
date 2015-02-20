class IntlOrder < ActiveRecord::Base
  
  has_many :intl_order_lines
  belongs_to :sam_customer, :class_name => "SamCustomer"
  belongs_to :install_to_org, :class_name => "Org"
  
  # IMPORTANT!!!!!!  THE FOLLOWING 5 FIELDS ARE NOT PART OF THE PERSISTENT MODEL FOR INTL ORDERS 
  
  def customer_name
    self.sam_customer ? self.sam_customer.root_org.name.strip : nil
  end
  
  def ucn
    self.sam_customer ? self.sam_customer.root_org.customer.ucn : nil
  end
  
  def country
    retval = nil
    if (self.sam_customer)
      intl_address_info = self.sam_customer.root_org.customer.intl_address_info
      if (intl_address_info)
        retval = intl_address_info.country.name.upcase
      end
    end
    retval
  end
  
  def country_id 
  end
  
  def po_num
  end
  
  def source_system_name
        
  end
  
  def invoice_num
  end
  
  def intl_business_unit_id    
  end
  
  def distributor_rep_user_id
  end
  
  def inside_sales_rep_user_id
  end
  
  def sales_rep_user_id
  end
  
end
