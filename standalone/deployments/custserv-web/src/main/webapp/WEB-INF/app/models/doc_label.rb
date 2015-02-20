class DocLabel < ActiveRecord::Base
  acts_as_cached
  set_table_name "doc_labels"
  has_many :doc_item_doc_labels, :dependent => :destroy
  has_many :doc_items, :through => :doc_item_doc_labels
  
  # Validation Rules
  validates_presence_of     :code, :display_text, :display_desc, :display_order
  validates_uniqueness_of   :code, :case_sensitive => false
  
end
# == Schema Information
#
# Table name: doc_labels
#
#  id            :integer(10)     not null, primary key
#  code          :string(255)     not null
#  display_text  :text            not null
#  display_desc  :string(255)     not null
#  notes         :text
#  display_order :integer(10)     not null
#  created_at    :datetime
#  updated_at    :datetime
#

