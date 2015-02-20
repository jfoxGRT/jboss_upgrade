class Product < ActiveRecord::Base
  acts_as_cached
  set_table_name "product"

  belongs_to :product_group
  has_one    :subcommunity, :foreign_key => "product_id", :class_name => "Subcommunity"
  belongs_to :hosted_product, :foreign_key => "hosted_product_id", :class_name => "Product"
  has_one :conversion_product_map_for_pre, :foreign_key => "pre_converted_product_id", :class_name => "ConversionProductMap"
  has_many :products_hosted, :foreign_key => "hosted_product_id", :class_name => "Product"
  has_one :post_entry_in_conversion_product_map, :foreign_key => "post_converted_product_id", :class_name => "ConversionProductMap"
  has_one :pre_entry_in_conversion_product_map, :foreign_key => "pre_converted_product_id", :class_name => "ConversionProductMap"
  has_one :conversion_product_map, :foreign_key => "product_id", :class_name => "ConversionProductMap"
  
  SRI_HOSTED_ID_VALUE = "100003" #Scholastic Reading Inventory Hosting Service
  SRC_HOSTED_ID_VALUE = "100004" #Scholastic Reading Counts! Hosting Service

end

# == Schema Information
#
# Table name: product
#
#  id                 :integer(10)     not null, primary key
#  description        :string(255)
#  id_provider        :string(255)     not null
#  id_value           :string(255)     not null
#  product_group_id   :integer(10)     not null
#  sam_server_product :boolean         default(TRUE), not null
#  hosted_product_id  :integer(10)
#  visibility_level   :string(1)       default("a"), not null
#

