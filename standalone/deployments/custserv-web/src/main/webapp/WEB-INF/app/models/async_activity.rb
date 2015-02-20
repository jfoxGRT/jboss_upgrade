class AsyncActivity < ActiveRecord::Base
  set_table_name "async_activity"
  belongs_to :status, :foreign_key => "status_id", :class_name => "AsyncActivityStatusType"
  has_many :async_file_uploads
  has_one :conversation_instance
end

# == Schema Information
#
# Table name: async_activity
#
#  id              :integer(10)     not null, primary key
#  status_id       :integer(10)
#  expiration_date :datetime
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  handler_tag     :string(255)     not null
#  handled_on      :datetime
#

