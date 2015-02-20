class Country < ActiveRecord::Base
  acts_as_cached
  set_table_name "country"
  has_many :state_provinces
  
  @@US_CODE = "US"
  
  def self.US_CODE
    @@US_CODE
  end
  
end

# == Schema Information
#
# Table name: country
#
#  id       :integer(10)     not null, primary key
#  code     :string(3)
#  iso_code :string(255)
#  name     :string(75)
#

