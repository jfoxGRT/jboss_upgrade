class PublicPrivate < ActiveRecord::Base
  acts_as_cached
  set_table_name "public_private"
end

# == Schema Information
#
# Table name: public_private
#
#  id          :integer(10)     not null, primary key
#  code        :string(3)
#  description :string(75)
#

