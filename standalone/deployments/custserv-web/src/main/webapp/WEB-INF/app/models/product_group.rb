class ProductGroup < ActiveRecord::Base
  acts_as_cached
  set_table_name "product_group"
  
  HOSTED_CODE = "HOSTED"
  
  @@TECH_SUPPORT = "SP"
  
  def self.TECH_SUPPORT
    @@TECH_SUPPORT
  end
  
end

# == Schema Information
#
# Table name: product_group
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

