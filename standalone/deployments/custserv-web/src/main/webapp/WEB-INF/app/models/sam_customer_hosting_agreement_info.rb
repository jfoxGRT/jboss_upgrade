class SamCustomerHostingAgreementInfo < ActiveRecord::Base
  set_table_name "sam_customer_hosting_agreement_info" 
  
end


#Table: sam_customer_hosting_agreement_info
#
#+-----------------+--------------+------+-----+---------+----------------+
#| Field           | Type         | Null | Key | Default | Extra          |
#+-----------------+--------------+------+-----+---------+----------------+
#| id              | int(11)      | NO   | PRI | NULL    | auto_increment |
#| sam_customer_id | int(10)      | NO   | MUL | NULL    |                |
#| first_name      | varchar(255) | NO   |     | NULL    |                |
#| last_name       | varchar(255) | NO   |     | NULL    |                |
#| title           | varchar(255) | YES  |     | NULL    |                |
#| phone_number    | varchar(255) | YES  |     | NULL    |                |
#| email_address   | varchar(255) | YES  |     | NULL    |                |
#| created_at      | datetime     | NO   |     | NULL    |                |
#+-----------------+--------------+------+-----+---------+----------------+