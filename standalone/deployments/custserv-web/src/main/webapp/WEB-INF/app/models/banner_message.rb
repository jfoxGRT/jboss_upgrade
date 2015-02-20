class BannerMessage < ActiveRecord::Base
  set_table_name "banner_message" 
  
  has_many :customer_banner_message, :dependent => :destroy 
  
  belongs_to :slms_banner_message
  
end

#Table name: banner_message
# 
#+------------------------+---------------+------+-----+---------+----------------+
#| Field                  | Type          | Null | Key | Default | Extra          |
#+------------------------+---------------+------+-----+---------+----------------+
#| id                     | int(11)       | NO   | PRI | NULL    | auto_increment |
#| message_name           | varchar(255)  | YES  |     | NULL    |                |
#| created_at             | datetime      | NO   |     | NULL    |                |
#| updated_at             | datetime      | NO   |     | NULL    |                |
#| last_posted            | datetime      | YES  |     | NULL    |                |
#| start_datetime         | datetime      | YES  |     | NULL    |                |
#| end_datetime           | datetime      | YES  |     | NULL    |                |
#| message                | varchar(5000) | NO   |     | NULL    |                |
#| post_to_sam_client     | tinyint(1)    | NO   |     | NULL    |                |
#| post_to_dashboard      | tinyint(1)    | NO   |     | NULL    |                |
#| post_to_studentaccess  | tinyint(1)    | NO   |     | NULL    |                |
#| post_to_educatoraccess | tinyint(1)    | NO   |     | NULL    |                |
#| distribution_scope     | varchar(255)  | NO   |     | NULL    |                |
#| server_scope           | varchar(255)  | YES  |     | NULL    |                |
#| creator                | varchar(255)  | YES  |     | NULL    |                |
#| is_historical          | tinyint(1)    | NO   |     | NULL    |                |
#| slms_message_type_code | int(10)       | NO   |     | NULL    |                |
#+------------------------+---------------+------+-----+---------+----------------+
