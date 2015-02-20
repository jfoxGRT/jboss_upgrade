class EsbMessageSrcSystem < ActiveRecord::Base
  set_table_name "esb_message_src_systems"
  
  def self.obtain_esb_message_src_system(name)
    src_system = EsbMessageSrcSystem.find_by_name(name)
    src_system = EsbMessageSrcSystem.create(:name => name) if src_system.nil?
    return src_system
  end
  
end

# == Schema Information
#
# Table name: esb_message_src_systems
#
#  id   :integer(10)     not null, primary key
#  name :string(255)     not null
#

