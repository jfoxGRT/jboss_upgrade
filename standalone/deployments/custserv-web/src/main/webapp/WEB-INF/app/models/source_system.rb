class SourceSystem < ActiveRecord::Base
  acts_as_cached
  set_table_name "source_system"
end

# == Schema Information
#
# Table name: source_system
#
#  id          :integer(10)     not null, primary key
#  code        :string(10)
#  description :string(75)
#

