class ReligiousAffiliation < ActiveRecord::Base
  acts_as_cached
  set_table_name "religious_affiliation"
end

# == Schema Information
#
# Table name: religious_affiliation
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

