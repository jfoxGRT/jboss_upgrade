class AuditMessageProp < ActiveRecord::Base
  set_table_name "audit_message_prop"
  
  belongs_to :audit_message
  
end
# == Schema Information
#
# Table name: audit_message_prop
#
#  id               :integer(10)     not null, primary key
#  audit_message_id :integer(10)     not null
#  name             :string(255)
#  value            :text
#

