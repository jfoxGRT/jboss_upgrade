class CreateSeatSummaryTable < ActiveRecord::Migration
  def self.up
    create_table "seat_summary", :force => true do |t|
      t.column "sam_customer_id",        :integer, :null => false, :references => :sam_customer
      t.column "sam_server_id",          :integer, :null => false, :references => nil
      t.column "subcommunity_id",        :integer, :null => false, :references => :subcommunity
      t.column "seat_status_id",         :integer, :null => false, :references => :seat_status
      t.column "seat_count",             :integer, :default => 0
    end
    execute "ALTER TABLE seat_summary ADD CONSTRAINT seatsum_server_subcom_status_unique UNIQUE (sam_customer_id, sam_server_id, subcommunity_id, seat_status_id)"    

    execute "DROP PROCEDURE IF EXISTS update_seat_summary"

    @storedproc_sql=<<EOF
CREATE PROCEDURE update_seat_summary (pServerId INT, pSeatBucketId INT, pSeatStatusId INT) 
BEGIN 
  DECLARE seatcount INT default 0; 
  DECLARE subcommunityId INT default 0; 
  DECLARE samcustomerId INT default -1;
  DECLARE existingSeatSummaryId INT default -1; 
  DECLARE samserverId INT default -1; 
  SELECT subcommunity_id 
    INTO subcommunityId  
    FROM seat_bucket sb 
    WHERE sb.id = pSeatBucketId; 
  SELECT sam_customer_id
    INTO samcustomerId 
    FROM seat_bucket sb 
    WHERE sb.id = pSeatBucketId; 
  IF (pServerId IS NOT NULL)
  THEN
    SELECT COUNT(1)  
      INTO seatcount  
      FROM seat s, seat_bucket sb 
      WHERE s.sam_server_id    = pServerId
        AND s.seat_status_id   = pSeatStatusId 
        AND sb.subcommunity_id = subcommunityId 
        AND s.seat_bucket_id   = sb.id
        AND sb.sam_customer_id = samcustomerId;
  ELSE
    SELECT COUNT(1)  
      INTO seatcount  
      FROM seat s, seat_bucket sb 
      WHERE s.sam_server_id    IS NULL
        AND s.seat_status_id   = pSeatStatusId 
        AND sb.subcommunity_id = subcommunityId 
        AND s.seat_bucket_id   = sb.id
        AND sb.sam_customer_id = samcustomerId;
  END IF;
  IF (pServerId IS NOT NULL)
   THEN
     SELECT ss.id 
       INTO existingSeatSummaryId
       FROM seat_summary ss
       WHERE ss.sam_server_id   = pServerId
         AND ss.subcommunity_id = subcommunityId
         AND ss.seat_status_id  = pSeatStatusId
         AND ss.sam_customer_id = samcustomerId
         LIMIT 1;
     SELECT pServerId INTO samserverId;
  ELSE
     SELECT ss.id 
       INTO existingSeatSummaryId
       FROM seat_summary ss
       WHERE ss.sam_server_id   = -1
         AND ss.subcommunity_id = subcommunityId
         AND ss.seat_status_id  = pSeatStatusId
         AND ss.sam_customer_id = samcustomerId
         LIMIT 1;
  END IF;
  IF(existingSeatSummaryId > 0)
   THEN 
     UPDATE seat_summary 
       SET seat_count = seatcount
       WHERE seat_summary.id = existingSeatSummaryId;
  ELSE
     INSERT INTO seat_summary(sam_customer_id, sam_server_id, subcommunity_id, seat_status_id, seat_count)  
       VALUES (samcustomerId, samserverId, subcommunityId, pSeatStatusId, seatcount)   ;
  END IF;  
 END 
EOF

    execute @storedproc_sql

    execute "DROP TRIGGER IF EXISTS seat_summary_update_trigger"
    @updatetrigger_sql=<<EOF
CREATE TRIGGER seat_summary_update_trigger AFTER UPDATE
  ON seat
  FOR EACH ROW 
  BEGIN
    call update_seat_summary(OLD.sam_server_id,OLD.seat_bucket_id,OLD.seat_status_id);
    call update_seat_summary(NEW.sam_server_id,NEW.seat_bucket_id,NEW.seat_status_id);
  END;
EOF
    execute @updatetrigger_sql

    execute "DROP TRIGGER IF EXISTS seat_summary_insert_trigger"
    @inserttrigger_sql=<<EOF
CREATE TRIGGER seat_summary_insert_trigger AFTER INSERT
  ON seat
  FOR EACH ROW 
  BEGIN
    call update_seat_summary(NEW.sam_server_id,NEW.seat_bucket_id,NEW.seat_status_id);
  END;
EOF
    execute @inserttrigger_sql

    execute "DROP TRIGGER IF EXISTS seat_summary_delete_trigger"
    @deletetrigger_sql=<<EOF
CREATE TRIGGER seat_summary_delete_trigger AFTER DELETE
  ON seat
  FOR EACH ROW 
  BEGIN
    call update_seat_summary(OLD.sam_server_id,OLD.seat_bucket_id,OLD.seat_status_id);
  END;
EOF
   execute @deletetrigger_sql
    
  end



  def self.down
    SeatSummary.delete_all
    drop_table :seat_summary
  end
end
