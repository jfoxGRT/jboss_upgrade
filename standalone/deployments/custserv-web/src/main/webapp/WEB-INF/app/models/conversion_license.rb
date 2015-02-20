class ConversionLicense < ActiveRecord::Base
  acts_as_cached  
  belongs_to :sam_customer
  belongs_to :product
  has_many :conversion_audits
  
  def self.find_by_sam_customer_and_product(sam_customer, product)
    ConversionLicense.find(:first, :conditions => ["sam_customer_id = ? and product_id = ?", sam_customer.id, product.id])
  end

=begin
  def self.find_by_sam_customer_and_product_ids(sam_customer, product_id_list)
  	conversion_license_list = []
  	
  	product_id_list.each do |product_id|
  		conversion_license_list << ConversionLicense.find(:first, 
  									:conditions => ["sam_customer_id = ? and product_id = ?", sam_customer.id, product_id])
  	end
  	
  	return conversion_license_list
  end
=end

end

# == Schema Information
#
# Table name: conversion_licenses
#
#  id                :integer(10)     not null, primary key
#  sam_customer_id   :integer(10)     not null
#  product_id        :integer(10)     not null
#  converted_count   :integer(10)     default(0), not null
#  unconverted_count :integer(10)     default(0), not null
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#

