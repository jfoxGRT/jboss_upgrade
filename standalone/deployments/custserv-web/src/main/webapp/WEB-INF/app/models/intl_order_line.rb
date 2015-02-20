class IntlOrderLine < ActiveRecord::Base
  
  belongs_to :product
  belongs_to :intl_order
  belongs_to :install_to_org, :class_name => "Org"
  belongs_to :sales_rep_user, :class_name => "User"
  belongs_to :inside_sales_rep_user, :class_name => "User"
  belongs_to :distributor_user, :class_name => "User"
  belongs_to :intl_order_type
  belongs_to :intl_business_unit, :class_name => "IntlBusinessUnit"
  
  def install_to_ucn
    @install_to_org.nil? ? nil : @install_to_org.customer.ucn
  end
  
end
