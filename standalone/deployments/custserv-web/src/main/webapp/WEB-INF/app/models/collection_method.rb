class CollectionMethod < ActiveRecord::Base
  acts_as_cached
  set_table_name "collection_method"
end

# == Schema Information
#
# Table name: collection_method
#
#  id          :integer(10)     not null, primary key
#  code        :string(255)
#  indicator   :string(255)
#  description :string(255)
#  text        :string(255)
#

