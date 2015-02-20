class SaplingCode < ActiveRecord::Base
  set_table_name "sapling_codes"
  belongs_to :sapling_type
end

# == Schema Information
#
# Table name: sapling_codes
#
#  id              :integer(10)     not null, primary key
#  sapling_type_id :integer(10)     not null
#  name            :string(255)     not null
#

