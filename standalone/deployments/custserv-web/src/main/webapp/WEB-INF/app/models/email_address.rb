class EmailAddress < ActiveRecord::Base
  set_table_name "email_address"
end

# == Schema Information
#
# Table name: email_address
#
#  id                         :integer(10)     not null, primary key
#  email_address_type_id      :integer(10)
#  deliv_status_id            :integer(10)
#  email_address              :string(255)
#  deliv_stats_date           :datetime
#  collection_method_id       :integer(10)
#  preferred_email_indicator  :string(255)
#  email_opt_in_status        :string(255)
#  email_opt_in_date          :datetime
#  last_acknowledged_date     :datetime
#  enterprise_email_indicator :string(255)
#  customer_id                :integer(10)
#  email_src_sys_cust_id      :string(255)
#  source_system_id           :integer(10)
#

