class DocItemDocLocation < ActiveRecord::Base
  set_table_name "doc_item_doc_location"
  belongs_to :doc_item
  belongs_to :doc_location
end

# == Schema Information
#
# Table name: doc_item_doc_location
#
#  id              :integer(10)     not null, primary key
#  doc_item_id     :integer(10)     not null
#  doc_location_id :integer(10)     not null
#

