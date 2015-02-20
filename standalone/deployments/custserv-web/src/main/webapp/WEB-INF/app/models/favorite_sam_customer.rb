class FavoriteSamCustomer < ActiveRecord::Base
  set_table_name "favorite_sam_customers"
  belongs_to :user
  belongs_to :sam_customer
end

# == Schema Information
#
# Table name: favorite_sam_customers
#
#  id              :integer(10)     not null, primary key
#  user_id         :integer(10)     not null
#  sam_customer_id :integer(10)     not null
#

