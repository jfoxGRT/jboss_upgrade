class AddSeatSummaryEvent < ActiveRecord::Migration
  def self.up
    # NOTE 1: if we have trouble running this migration, try granting event and trigger privs, via:
    #   GRANT event on scholastic.* to scholastic@localhost
    #   GRANT trigger on scholastic.* to scholastic@localhost
    # NOTE 2: in order for the Event system to actually work, the event scheduler needs to be enabled in mysql.  It is turned
    #  off by default.  To turn it on, exec this sql:
    #   SET GLOBAL event_scheduler = 'ON';
    #  (however, I don't think that thi survives a mysql restart)
    #  Another option is to put it in the my.cnf (if you don't have one, put it in your data dir,
    #    on mac and linux, this is /usr/local/mysql/data).
    #  Add this to your my.cnf and restart mysql:
    #   [mysqld]
    #   event_scheduler=ON

    create_table "seat_summary_event_runner", :force => true do |t|
      t.column "start_time",             :datetime, :null => false 
      t.column "max_seat_updated_time",  :datetime, :null => false
      t.column "recalc_count",       :integer, :default => 0
      t.column "end_time",               :datetime
    end
    
    # Note: recalc_count is not how many rows were updated, rather it is the number of times the proc was executed due to the event running.
    #    The reason it isn't the same is because there can be multiple seat buckets for a single sam_server-subcommunity-seatType combo (due to sc_entitlement_type diffs)
    
    add_index :seat_summary_event_runner, [:max_seat_updated_time]    
    
    #timestamps are calculated as current time upon insertion of a row (if the value is unspecified)
    execute "ALTER TABLE seat_summary ADD COLUMN timetamp timestamp"
    
    
#    @table_sql=<<EOF
#CREATE TABLE  seat_summary_event_runner (
#  id int(11) NOT NULL AUTO_INCREMENT,
#  start_time datetime NOT NULL,
#  max_seat_updated_time datetime NOT NULL,
#  recalc_count INT default 0,
#  end_time datetime NULL,
#  PRIMARY KEY (id)
#)
#EOF
#
#    execute @table_sql
    
    @storedproc_sql=<<EOF
/*
 This stored proc spins thru the seat table looking for rows that have been updated since pChangedSinceTime. 
 If it finds any, it updates every row in the seat summary table for that sam_customer_id by completely recalculating
 it.  The return value, passed back in the OUT param pExecCount, is the number of rows in seat_summary
 that were recalculated.
*/    
CREATE PROCEDURE refresh_seat_summary_table(IN pChangedSinceTime DATETIME, OUT pExecCount INT)
BEGIN
  DECLARE done           INT DEFAULT 0;
  DECLARE serverId       INT;
  DECLARE seatBucketId   INT;
  DECLARE seatStatusId   INT;
  DECLARE nowTime        DATETIME DEFAULT NOW();
  DECLARE seatCur        CURSOR FOR
    SELECT DISTINCT s.sam_server_id,s.seat_bucket_id,s.seat_status_id  FROM seat s, seat_bucket sb 
      WHERE s.seat_bucket_id = sb.id
        AND sb.sam_customer_id in (
            SELECT DISTINCT sb2.sam_customer_id FROM seat s2, seat_bucket sb2 
              WHERE s2.seat_bucket_id = sb2.id
                AND s2.updated_at > pChangedSinceTime        
                AND s2.updated_at < nowTime              );
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;  

  select 0 into pExecCount;
  /* delete ALL the old stuff for these customers - NOTE: this is the same query as above. */
  delete from seat_summary where sam_customer_id in (
              SELECT DISTINCT sb2.sam_customer_id FROM seat s2, seat_bucket sb2 
              WHERE s2.seat_bucket_id = sb2.id
                AND s2.updated_at > pChangedSinceTime
                AND s2.updated_at < nowTime              );
  /* now start reconstructing for those customers */
  OPEN seatCur;
  seatloop: LOOP
    FETCH seatCur INTO serverId,seatBucketId,seatStatusId;
    IF done THEN
      LEAVE seatloop;
    ELSE
      call update_seat_summary(serverId, seatBucketId, seatStatusId);
      select pExecCount + 1 into pExecCount; 
    END IF;
  END LOOP seatloop;
  CLOSE seatCur;
END 
EOF
 
    execute @storedproc_sql
    
    @event_sql=<<EOF
/*
 This is the event that is fired periodically to automatically refresh the seat_summary table. 
 It looks at the timestamp that it recorded the last time it ran (SEAT_SUMMARY_EVENT_RUNNER.max_seat_updated_time)
 and sees if there were updates to the SEAT table after that time.  If so, it recalculates the seat_summary rows for 
 every seat that changed (via the refresh_seat_summary_table() proc.).
 It also records the start and stop time of each event so we can see how fast it ran and how many rows it 
 updated during each run.  This info is purged by the event itself so that the table doesn't get that big.
*/
CREATE EVENT seat_summary_update_event
    ON SCHEDULE
      EVERY 2 MINUTE
      STARTS addtime(now(), '00:00:02')
    DO
      BEGIN
        DECLARE job_start_time                DATETIME;
        DECLARE current_max_seat_updated_time DATETIME;
        DECLARE seat_count                    INT      default 0;
        DECLARE changedSinceTime              DATETIME;
        DECLARE execCount                     INT default 0;
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION   BEGIN  END;

        select count(1) into seat_count from seat;
        IF (seat_count>0)
        THEN
          SELECT now() into job_start_time;
          SELECT max(updated_at) into current_max_seat_updated_time from seat;
          SELECT ifnull(max(max_seat_updated_time), DATE('2000-1-1 01:02:03')) INTO changedSinceTime FROM seat_summary_event_runner;
          INSERT into seat_summary_event_runner(start_time, max_seat_updated_time) values (job_start_time, current_max_seat_updated_time);
          CALL refresh_seat_summary_table(changedSinceTime, execCount);
          update seat_summary_event_runner set end_time=now(), recalc_count=execCount where start_time=job_start_time;
          delete from seat_summary_event_runner where start_time < subdate(now(),14); 
        END IF;
    END 
EOF

    execute @event_sql
  end

  def self.down
    remove_index :seat_summary_event_runner, :column => [:max_seat_updated_time]
    execute "DROP PROCEDURE IF EXISTS refresh_seat_summary_table"
    execute "DROP EVENT IF EXISTS seat_summary_update_event"
    drop_table :seat_summary_event_runner    
    remove_column :seat_summary, :timestamp
  end
end
