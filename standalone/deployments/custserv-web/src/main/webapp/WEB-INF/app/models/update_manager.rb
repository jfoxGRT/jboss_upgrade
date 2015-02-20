class UpdateManager < ActiveRecord::Base
  set_table_name "update_manager"
  belongs_to :sam_customer
  belongs_to :sam_server
  
  def self.getGlobalRecord()
    UpdateManager.find_by_sql("select * from update_manager where sam_server_id IS NULL and sam_customer_id IS NULL")[0]
  end
  
  def self.getCustomerOverrides()
    UpdateManager.find(:all, :conditions => "sam_customer_id IS NOT NULL and sam_server_id IS NULL")
  end
  
  def self.getServerOverrides()
    UpdateManager.find(:all, :conditions => "sam_customer_id IS NOT NULL and sam_server_id IS NOT NULL")
  end
    
end

# == Schema Information
#
# Table name: update_manager
#
#  id              :integer(10)     not null, primary key
#  sam_customer_id :integer(10)
#  sam_server_id   :integer(10)
#  active          :integer(10)     not null
#

