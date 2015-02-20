class SaplingMeta < ActiveRecord::Base
  set_table_name "sapling_meta"
  belongs_to :sapling
end

# == Schema Information
#
# Table name: sapling_meta
#
#  id         :integer(10)     not null, primary key
#  sapling_id :integer(10)     not null
#  name       :string(255)     not null
#  value      :string(5000)
#

