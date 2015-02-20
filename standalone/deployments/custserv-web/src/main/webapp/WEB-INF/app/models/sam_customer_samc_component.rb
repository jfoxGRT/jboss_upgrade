class SamCustomerSamcComponent < ActiveRecord::Base
	set_table_name "sam_customer_samc_component"
	belongs_to :samc_component
	belongs_to :sam_customer
	
	def self.find_by_sam_customer_and_component_code(sam_customer, code)
		SamCustomerSamcComponent.find(:first, :select => "scsc.*", :joins => "scsc inner join samc_components sc on scsc.samc_component_id = sc.id",
										:conditions => ["sc.code = ? and scsc.sam_customer_id = ?", code, sam_customer.id])
	end
	
end

# == Schema Information
#
# Table name: sam_customer_samc_component
#
#  id                :integer(10)     not null, primary key
#  samc_component_id :integer(10)     not null
#  sam_customer_id   :integer(10)     not null
#  activation_date   :datetime
#  status            :string(1)
#  version           :string(10)
#

