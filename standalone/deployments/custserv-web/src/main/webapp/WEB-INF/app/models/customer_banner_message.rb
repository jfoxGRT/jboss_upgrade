class CustomerBannerMessage < ActiveRecord::Base
  set_table_name "customer_banner_message"  
  
  belongs_to :banner_message
  
  def get_assoc_ucns(id)
    ucn_list = CustomerBannerMessage.where("banner_message_id = ?", id)
  end
  
end

# Table name: customer_banner_message
#
#+-------------------+---------+------+-----+---------+----------------+
#| Field             | Type    | Null | Key | Default | Extra          |
#+-------------------+---------+------+-----+---------+----------------+
#| id                | int(11) | NO   | PRI | NULL    | auto_increment |
#| sam_customer_id   | int(10) | NO   | MUL | NULL    |                |
#| banner_message_id | int(10) | NO   | MUL | NULL    |                |
#+-------------------+---------+------+-----+---------+----------------+