class ResponseCode < ActiveRecord::Base
  acts_as_cached
  set_table_name "response_code"
end

# == Schema Information
#
# Table name: response_code
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#  text        :string(255)
#

