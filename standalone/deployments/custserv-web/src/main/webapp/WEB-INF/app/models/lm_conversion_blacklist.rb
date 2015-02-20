class LmConversionBlacklist < ActiveRecord::Base
  set_table_name "lm_conversion_blacklist"
  
  belongs_to :sam_customer
  
end

# == Schema Information
#
# Table name: lm_conversion_blacklist
#
#  id              :integer(10)     not null, primary key
#  sam_customer_id :integer(10)     not null
#

