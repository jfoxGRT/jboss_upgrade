class DocItem < ActiveRecord::Base
  belongs_to :user_types, :foreign_key => "user_type_id", :class_name => "UserType"
  has_many   :doc_item_doc_labels, :dependent => :destroy
  has_many   :doc_labels, :through => :doc_item_doc_labels, :dependent => :destroy do
    def with_code(code)
      find :first, :conditions => ['code = ?', code]
    end
  end
  has_many   :doc_item_doc_locations, :dependent => :destroy  
  has_many   :doc_locations, :through => :doc_item_doc_locations, :dependent => :destroy do
    def with_code(code)
      find :first, :conditions => ['code = ?', code]
    end
  end  
  
  attr_accessor :user_selected_doc_label_ids
  attr_accessor :user_selected_doc_location_ids  
  after_save    :update_doc_labels     # called after activerecord base.save
  after_save    :update_doc_locations  # called after activerecord base.save
  
  @@STATUS_PUBLISHED = 'p'
  @@STATUS_NOT_PUBLISHED = 'n'
  @@STATUS_UNDER_REVIEW = 'r'
  
  # Keep named_scope after static variable definitions used in named_scope  
  named_scope :published,                     :conditions => {:publish_status => @@STATUS_PUBLISHED}
  named_scope :under_review,                  :conditions => {:publish_status => @@STATUS_UNDER_REVIEW}
  named_scope :published_or_under_review,     :conditions => {:publish_status => [@@STATUS_PUBLISHED, @@STATUS_UNDER_REVIEW]}
  named_scope :for_customer,                  :include => :user_types, :conditions => ['user_types.code = ?', 'c']
  named_scope :for_doc_location_code,         lambda { |dloc_code| {:include => :doc_locations, :conditions => ['doc_locations.code = ?', dloc_code] } }    
  named_scope :by_doc_order,                  :order => :display_order
  
  def self.STATUS_PUBLISHED
    @@STATUS_PUBLISHED
  end
  
  def self.STATUS_NOT_PUBLISHED
  	@@STATUS_NOT_PUBLISHED
  end
  
  def self.STATUS_UNDER_REVIEW
  	@@STATUS_UNDER_REVIEW
  end      
  
  
  # Validation Rules
  validates_presence_of     :ref_number, :user_type_id, :question, :display_order, :publish_status
  validates_length_of       :publish_status,    :within => 1..1 
  
  
  # Purpose: Return display text of publish_status
  #
  def publish_status_text
    case self.publish_status
      when @@STATUS_PUBLISHED     : "Published"
      when @@STATUS_NOT_PUBLISHED : "Not Published"
      when @@STATUS_UNDER_REVIEW  : "Under Review"
      else "unknown"
    end
  end


  # Purpose: Maintain many-to-many DocItemDocLabel mapping table (DocItem to DocLabel)
  #   * Called via the "after_save" activerecord method defined at top of this model object
  #   * variable "user_selected_doc_label_ids" is a non-db attribute of doc_item model 
  #     object, and populated in the doc_items_controller  
  #
  def update_doc_labels
    unless user_selected_doc_label_ids.nil?
      # Delete all existing doc-to-label relationships that were removed by user
      self.doc_item_doc_labels.each do |didl|
        didl.destroy unless user_selected_doc_label_ids.include?(didl.doc_label_id.to_s)
        user_selected_doc_label_ids.delete(didl.doc_label_id.to_s)
      end 
      # Add new added doc-to-label relationships
      user_selected_doc_label_ids.each do |usdl|
        self.doc_item_doc_labels.create(:doc_label_id => usdl) unless usdl.blank?
      end
      reload
      self.user_selected_doc_label_ids = nil
    end
  end
  
  
  # Purpose: Maintain many-to-many DocItemDocLocation mapping table (DocItem to DocLocation)
  #   * Called via the "after_save" activerecord method defined at top of this model object
  #   * variable "user_selected_doc_loction_ids" is a non-db attribute of doc_item model 
  #     object, and populated in the doc_items_controller  
  #
  def update_doc_locations
    unless user_selected_doc_location_ids.nil?
      # Delete all existing doc-to-location relationships that were removed by user
      self.doc_item_doc_locations.each do |didl|
        didl.destroy unless user_selected_doc_location_ids.include?(didl.doc_location_id.to_s)
        user_selected_doc_location_ids.delete(didl.doc_location_id.to_s)
      end 
      # Add new added doc-to-location relationships
      user_selected_doc_location_ids.each do |usdl|
        self.doc_item_doc_locations.create(:doc_location_id => usdl) unless usdl.blank?
      end
      reload
      self.user_selected_doc_location_ids = nil
    end
  end
  
end

# == Schema Information
#
# Table name: doc_items
#
#  id             :integer(10)     not null, primary key
#  ref_number     :integer(10)     not null
#  user_type_id   :integer(10)     not null
#  question       :text            not null
#  answer         :text
#  notes          :text
#  display_order  :integer(10)     not null
#  created_at     :datetime
#  updated_at     :datetime
#  publish_status :string(1)       default("r"), not null
#

