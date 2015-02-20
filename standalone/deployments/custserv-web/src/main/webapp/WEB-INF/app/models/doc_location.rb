class DocLocation < ActiveRecord::Base
  acts_as_cached
  set_table_name "doc_locations"
  has_many :doc_item_doc_locations, :dependent => :destroy
  has_many :doc_items, :through => :doc_item_doc_locations  
  
  # Validation Rules
  validates_presence_of     :code, :display_location, :display_text
  validates_uniqueness_of   :code, :case_sensitive => false
  
end

# == Schema Information
#
# Table name: doc_locations
#
#  id               :integer(10)     not null, primary key
#  code             :string(255)     not null
#  display_location :string(255)     not null
#  display_text     :text            not null
#

