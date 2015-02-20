class DocItemDocLabel < ActiveRecord::Base
  set_table_name "doc_item_doc_label"
  belongs_to :doc_item
  belongs_to :doc_label
end

# == Schema Information
#
# Table name: doc_item_doc_label
#
#  id           :integer(10)     not null, primary key
#  doc_item_id  :integer(10)     not null
#  doc_label_id :integer(10)     not null
#

