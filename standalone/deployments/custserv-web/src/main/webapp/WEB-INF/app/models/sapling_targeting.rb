class SaplingTargeting < ActiveRecord::Base
  set_table_name "sapling_targeting"
  belongs_to :sapling 
  
  def self.get_sam_customer_name(sam_customer_id)
    name = self.find_by_sql(["select name as the_name from sam_customer where id = ?", sam_customer_id])[0].the_name
	return name
  end
  
  def self.get_product_name(product_id)
    name = self.find_by_sql(["select description as the_name from product where id = ?", product_id])[0].the_name
	return name
  end
  
  def self.get_server_name(server_id)
    name = self.find_by_sql(["select name as the_name from sam_server where id = ?", server_id])[0].the_name
	return name
  end
  
end
# == Schema Information
#
# Table name: sapling_targeting
#
#  id              :integer(10)     not null, primary key
#  sapling_id      :integer(10)     not null
#  white_list      :boolean         not null
#  sam_server_id   :integer(10)
#  sam_customer_id :integer(10)
#  product_id      :integer(10)
#

