class ConversionProductMap < ActiveRecord::Base
  acts_as_cached  
  belongs_to :product, :foreign_key => "product_id", :class_name => "Product"    
  belongs_to :pre_converted_product, :foreign_key => "pre_converted_product_id", :class_name => "Product"    
  belongs_to :post_converted_product, :foreign_key => "post_converted_product_id", :class_name => "Product"    
end
# == Schema Information
#
# Table name: conversion_product_maps
#
#  id                        :integer(10)     not null, primary key
#  product_id                :integer(10)     not null
#  pre_converted_product_id  :integer(10)     not null
#  post_converted_product_id :integer(10)     not null
#  created_at                :datetime        not null
#  updated_at                :datetime        not null
#

