class ProcessContext < ActiveRecord::Base
  set_table_name "process_contexts"
  belongs_to :samc_process, :foreign_key => "process_id", :class_name => "SamcProcess"
end

# == Schema Information
#
# Table name: process_contexts
#
#  id         :integer(10)     not null, primary key
#  name       :string(40)      not null
#  value      :string(255)     not null
#  process_id :integer(10)     not null
#

