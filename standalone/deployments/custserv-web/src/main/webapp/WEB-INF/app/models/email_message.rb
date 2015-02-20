class EmailMessage < ActiveRecord::Base
  set_table_name "email_message"
  
  belongs_to :email_type
  belongs_to :email_stream
  belongs_to :user  
  
end

# == Schema Information
#
# Table name: email_message
#
#  id                :integer(10)     not null, primary key
#  email_type_id     :integer(10)     not null
#  user_id           :integer(10)
#  recipient_address :string(255)     not null
#  subject           :string(255)     not null
#  text_body         :text            not null
#  html_body         :text            not null
#  generated_date    :datetime        not null
#  sent_date         :datetime
#  email_stream_id   :integer(10)
#  ignored_date      :datetime
#  auth_user_id      :integer(10)
#  attachment_file   :string(255)
#  attachment_name   :string(255)
#

