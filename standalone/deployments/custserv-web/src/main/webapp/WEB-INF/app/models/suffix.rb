class Suffix < ActiveRecord::Base
  acts_as_cached
  set_table_name "suffix"
end
# == Schema Information
#
# Table name: suffix
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

