class CustomerRole < ActiveRecord::Base
  acts_as_cached
  set_table_name "customer_role"
  belongs_to :customer
  belongs_to :related_customer, :class_name => "Customer", :foreign_key => "related_customer_id" 
  belongs_to :role_type
  belongs_to :role_group
  belongs_to :relationship_type
end

# == Schema Information
#
# Table name: customer_role
#
#  id                    :integer(10)     not null, primary key
#  customer_id           :integer(10)
#  related_customer_id   :integer(10)
#  relationship_type_id  :integer(10)
#  role_group_id         :integer(10)
#  role_type_id          :integer(10)
#  related_role_group_id :integer(10)
#  related_role_type_id  :integer(10)
#

