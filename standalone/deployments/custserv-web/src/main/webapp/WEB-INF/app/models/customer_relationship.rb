class CustomerRelationship < ActiveRecord::Base
  set_table_name "customer_relationship"
  belongs_to :customer
  belongs_to :related_customer, :class_name => "Customer", :foreign_key => "related_customer_id" 
  belongs_to :relationship_type
  belongs_to :relationship_category
end

# == Schema Information
#
# Table name: customer_relationship
#
#  id                       :integer(10)     not null, primary key
#  customer_id              :integer(10)
#  related_customer_id      :integer(10)
#  relationship_type_id     :integer(10)     not null
#  effective                :date            not null
#  end                      :date
#  relationship_category_id :integer(10)
#  created_at               :datetime
#  updated_at               :datetime
#

