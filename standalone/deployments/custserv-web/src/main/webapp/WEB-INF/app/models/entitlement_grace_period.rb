class EntitlementGracePeriod < ActiveRecord::Base
  set_table_name "entitlement_grace_periods"
  belongs_to :entitlement
  belongs_to :grace_period
end

# == Schema Information
#
# Table name: entitlement_grace_periods
#
#  id              :integer(10)     not null, primary key
#  entitlement_id  :integer(10)     not null
#  grace_period_id :integer(10)     not null
#  start_date      :datetime
#  end_date        :datetime
#

