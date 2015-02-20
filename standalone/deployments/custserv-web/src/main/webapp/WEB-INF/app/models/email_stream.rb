class EmailStream < ActiveRecord::Base
  belongs_to :sam_customer
  belongs_to :email_group
  belongs_to :current_email_type
  has_many :email_messages
end

# == Schema Information
#
# Table name: email_streams
#
#  id                    :integer(10)     not null, primary key
#  sam_customer_id       :integer(10)
#  email_group_id        :integer(10)
#  current_email_type_id :integer(10)     not null
#  send_count            :integer(5)      default(1), not null
#  open_stream           :boolean
#  created_at            :datetime
#  updated_at            :datetime
#  recipient_address     :string(255)
#

