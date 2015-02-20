class ConversionAudit < ActiveRecord::Base
  acts_as_cached  
  belongs_to :conversion_license
  belongs_to :source_user, :foreign_key => "source_user_id", :class_name => "User"
  belongs_to :source_entitlement, :foreign_key => "source_entitlement_id", :class_name => "Entitlement"  
end

# == Schema Information
#
# Table name: conversion_audits
#
#  id                         :integer(10)     not null, primary key
#  conversion_license_id      :integer(10)     not null
#  starting_converted_count   :integer(10)     default(0), not null
#  ending_converted_count     :integer(10)     default(0), not null
#  starting_unconverted_count :integer(10)     default(0), not null
#  ending_unconverted_count   :integer(10)     default(0), not null
#  source_user_id             :integer(10)
#  source_entitlement_id      :integer(10)
#  reason                     :integer(10)     not null
#  created_at                 :datetime        not null
#  updated_at                 :datetime        not null
#

