class BannerMessageBlacklist < ActiveRecord::Base
  set_table_name "banner_message_blacklist" 
     
end


#Table name: banner_message_blacklist;
#+-----------------+---------+------+-----+---------+----------------+
#| Field           | Type    | Null | Key | Default | Extra          |
#+-----------------+---------+------+-----+---------+----------------+
#| id              | int(11) | NO   | PRI | NULL    | auto_increment |
#| sam_customer_id | int(10) | NO   | MUL | NULL    |                |
#+-----------------+---------+------+-----+---------+----------------+