class Moratorium < ActiveRecord::Base
  set_table_name "moratorium" 
  
end


#Table name: moratorium
#
#+-------------------+------------+------+-----+---------+----------------+
#| Field             | Type       | Null | Key | Default | Extra          |
#+-------------------+------------+------+-----+---------+----------------+
#| id                | int(11)    | NO   | PRI | NULL    | auto_increment |
#| start_datetime    | datetime   | NO   |     | NULL    |                |
#| end_datetime      | datetime   | NO   |     | NULL    |                |
#| hosted_servers    | tinyint(1) | YES  |     | NULL    |                |
#| local_servers     | tinyint(1) | YES  |     | NULL    |                |
#| sapling_content   | tinyint(1) | YES  |     | NULL    |                |
#| sapling_component | tinyint(1) | YES  |     | NULL    |                |
#+-------------------+------------+------+-----+---------+----------------+