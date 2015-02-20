class AsyncActivityStatusType < ActiveRecord::Base
  acts_as_cached
  set_table_name "async_activity_status_type"
end

# == Schema Information
#
# Table name: async_activity_status_type
#
#  id   :integer(10)     not null, primary key
#  code :string(255)     not null
#  name :string(255)     not null
#

