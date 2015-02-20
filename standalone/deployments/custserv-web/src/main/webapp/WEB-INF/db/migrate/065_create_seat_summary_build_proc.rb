class CreateSeatSummaryBuildProc < ActiveRecord::Migration
  def self.up
    execute "DROP PROCEDURE IF EXISTS rebuild_ss_for_servers_and_statuses"
    execute "DROP PROCEDURE IF EXISTS rebuild_ss_for_servers"
    execute "DROP PROCEDURE IF EXISTS rebuild_seat_summary_table"

    @storedproc1_sql=<<EOF
CREATE PROCEDURE rebuild_ss_for_servers_and_statuses(IN pServerId INT, IN pSeatBucketId INT)
BEGIN
  DECLARE statusId INT default 0;
  DECLARE done       INT DEFAULT 0;
  DECLARE seatStatusCur CURSOR FOR
    select id from seat_status;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;  
  
  OPEN seatStatusCur;
  seatstatusloop: LOOP
    FETCH seatStatusCur INTO statusId;
    IF done THEN
       LEAVE seatstatusloop;
    ELSE
       CALL update_seat_summary(pServerId, pSeatBucketId, statusId);
    END IF;
  END LOOP seatstatusloop;
  CLOSE seatStatusCur;
END 
EOF

    execute @storedproc1_sql

    @storedproc2_sql=<<EOF
CREATE PROCEDURE rebuild_ss_for_servers(IN pSeatBucketId INT)
BEGIN
  DECLARE serverId INT default 0;
  DECLARE done INT default 0;
  DECLARE serverCur CURSOR FOR
    select id from sam_server where sam_customer_id in (
      select sam_customer_id from seat_bucket where id = pSeatBucketId
    );
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;  
  
  call rebuild_ss_for_servers_and_statuses(null, pSeatBucketId);
  OPEN serverCur;
  serverLoop: LOOP
    FETCH serverCur into serverId;
    IF done THEN
      LEAVE serverLoop;
    ELSE 
      call rebuild_ss_for_servers_and_statuses(serverId, pSeatBucketId);      
    END IF;
  END LOOP serverLoop;
  CLOSE serverCur;
END    
EOF
      
    execute @storedproc2_sql

    @storedproc3_sql=<<EOF
CREATE PROCEDURE rebuild_seat_summary_table()
BEGIN
  DECLARE seatBucketId INT default 0;
  DECLARE done       INT DEFAULT 0;
  DECLARE seatBucketCur CURSOR FOR
    select id from seat_bucket;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;  

  DELETE from seat_summary;
  ALTER TABLE seat_summary AUTO_INCREMENT = 1;
  OPEN seatBucketCur;
  seatbucketloop: LOOP
    FETCH seatBucketCur INTO seatBucketId;
    IF done THEN
      LEAVE seatbucketloop;
    ELSE
      call rebuild_ss_for_servers(seatBucketId);                
    END IF;
  END LOOP seatbucketloop;
  CLOSE seatBucketCur;
  DELETE from seat_summary where seat_count=0;
END    
EOF

    execute @storedproc3_sql

  end



  def self.down
    execute "DROP PROCEDURE IF EXISTS rebuild_ss_for_servers_and_statuses"
    execute "DROP PROCEDURE IF EXISTS rebuild_ss_for_servers"
    execute "DROP PROCEDURE IF EXISTS rebuild_seat_summary_table"
  end
  
end
