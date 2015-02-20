class JobTitle < ActiveRecord::Base
  acts_as_cached
  set_table_name "job_title"
  belongs_to :user
  
  @@OTHER_CODE = "OTH"
  
  def self.OTHER_CODE
    @@OTHER_CODE
  end
  
end
# == Schema Information
#
# Table name: job_title
#
#  id            :integer(10)     not null, primary key
#  code          :string(255)     not null
#  description   :string(255)     not null
#  display_order :integer(10)     not null
#

