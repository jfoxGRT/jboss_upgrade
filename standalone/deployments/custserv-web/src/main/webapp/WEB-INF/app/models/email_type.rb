class EmailType < ActiveRecord::Base
  acts_as_cached
  set_table_name "email_type"
  
  belongs_to :email_group
  
end

# == Schema Information
#
# Table name: email_type
#
#  id                              :integer(10)     not null, primary key
#  code                            :string(40)
#  description                     :string(255)
#  email_group_id                  :integer(10)
#  max_send_count                  :integer(5)
#  sequence_number                 :integer(5)      default(1), not null
#  customer_mail                   :boolean         default(TRUE)
#  status                          :integer(10)     default(1), not null
#  available_in_test_email_utility :boolean         default(FALSE), not null
#

