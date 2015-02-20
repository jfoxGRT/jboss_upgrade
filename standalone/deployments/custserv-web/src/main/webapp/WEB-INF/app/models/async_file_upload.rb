class AsyncFileUpload < ActiveRecord::Base
  set_table_name "async_file_upload"
  belongs_to :async_activity
  belongs_to :status, :foreign_key => "status_id", :class_name => "AsyncFileUploadStatusType"
end

# == Schema Information
#
# Table name: async_file_upload
#
#  id                           :integer(10)     not null, primary key
#  async_activity_id            :integer(10)     not null
#  status_id                    :integer(10)
#  file_name                    :string(2048)    not null
#  request_date                 :datetime
#  upload_date                  :datetime
#  expired_on_date              :datetime
#  expired_by_agent             :boolean
#  created_at                   :datetime        not null
#  updated_at                   :datetime        not null
#  failure_date                 :datetime
#  file_alias                   :string(255)
#  file_extension               :string(255)
#  server_report_request_id     :integer(10)
#

