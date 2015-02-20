class GracePeriod < ActiveRecord::Base
  acts_as_cached
  set_table_name "grace_period"
end

# == Schema Information
#
# Table name: grace_period
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  description :string(255)
#

