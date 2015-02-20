class Subcommunity < ActiveRecord::Base
  acts_as_cached

  set_table_name "subcommunity"
  belongs_to :community
  belongs_to :product
  
  SRI_CODE = "SRI"
  SRC_CODE = "SRC"
  R180_A_CODE = "R180_A"
  R180_B_CODE = "R180_B"
  R180_C_CODE = "R180_C"
  E21_I_CODE = "XT_I"
  E21_II_CODE = "XT_II"
  E21_III_CODE = "XT_III"
  S44_CODE = "S44"
  
end

# == Schema Information
#
# Table name: subcommunity
#
#  id                          :integer(10)     not null, primary key
#  name                        :string(128)
#  code                        :string(255)
#  license_seed_code           :string(255)
#  community_id                :integer(10)
#  product_id                  :integer(10)
#  suppress_entitlement_update :boolean         default(FALSE)
#  display_order               :integer(10)     default(999), not null
#

