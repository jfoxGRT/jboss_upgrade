class BlackoutFilter < ActiveRecord::Base
  set_table_name "blackout_filter"
end
# == Schema Information
#
# Table name: blackout_filter
#
#  id              :integer(10)     not null, primary key
#  sam_customer_id :integer(10)     not null
#  start_hour      :integer(10)
#  end_hour        :integer(10)
#  level           :string(255)     not null
#  monday          :boolean         default(TRUE), not null
#  tuesday         :boolean         default(TRUE), not null
#  wednesday       :boolean         default(TRUE), not null
#  thursday        :boolean         default(TRUE), not null
#  friday          :boolean         default(TRUE), not null
#  saturday        :boolean         default(TRUE), not null
#  sunday          :boolean         default(TRUE), not null
#

