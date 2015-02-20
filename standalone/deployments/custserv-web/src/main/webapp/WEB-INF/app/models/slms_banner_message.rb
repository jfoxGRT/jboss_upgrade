class SlmsBannerMessage < ActiveRecord::Base
  set_table_name "slms_banner_message" 
  
  has_many :banner_message
 
end


#table slms_banner_message;
#+--------------------------+--------------+------+-----+---------+----------------+
#| Field                    | Type         | Null | Key | Default | Extra          |
#+--------------------------+--------------+------+-----+---------+----------------+
#| id                       | int(11)      | NO   | PRI | NULL    | auto_increment |
#| message_type_code        | int(10)      | NO   |     | NULL    |                |
#| icon_url                 | varchar(255) | NO   |     | NULL    |                |
#| message_type_description | varchar(255) | NO   |     | NULL    |                |
#+--------------------------+--------------+------+-----+---------+----------------+