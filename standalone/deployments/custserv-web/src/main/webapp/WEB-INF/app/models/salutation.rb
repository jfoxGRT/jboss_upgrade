class Salutation < ActiveRecord::Base
  acts_as_cached
  set_table_name "salutation"
end
# == Schema Information
#
# Table name: salutation
#
#  id            :integer(10)     not null, primary key
#  code          :string(3)
#  description   :string(75)
#  display_order :integer(10)     default(0), not null
#

