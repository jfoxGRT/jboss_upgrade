class AddReallocateSeatsStoredproc < ActiveRecord::Migration
  def self.up
    execute "DROP PROCEDURE IF EXISTS reallocate_seats"
    
    @storedproc_sql=<<EOF
CREATE PROCEDURE reallocate_seats (IN pNumberOfSeats INT, IN pSourceSeatBucketId INT, IN pDestSeatBucketId INT) 
BEGIN
  DECLARE seatcount  INT DEFAULT 0;
  DECLARE done       INT DEFAULT 0;
  DECLARE origSeatId INT DEFAULT NULL;
  /* grab all orig_seat_id's for this seatbucket that are LIVE */
  DECLARE seatcur CURSOR FOR
     SELECT DISTINCT s.orig_seat_id FROM seat s
       WHERE s.seat_status_id != (SELECT ss.id FROM seat_status ss WHERE code = "I")
         AND s.seat_bucket_id  = pSourceSeatBucketId
       ORDER BY s.orig_seat_id DESC;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  OPEN seatcur;
  supercool: LOOP
    FETCH seatcur INTO origSeatId;
    IF done OR (seatcount >= pNumberOfSeats) THEN
       LEAVE supercool;
    ELSE
       UPDATE seat
         SET seat_bucket_id = pDestSeatBucketId, updated_at = NOW()
         WHERE orig_seat_id = origSeatId;
       SELECT seatcount + 1 INTO seatcount;
    END IF;
  END LOOP supercool;
  CLOSE seatcur;
  SELECT seatcount; /* return number seats moved */
 END    
EOF
    execute @storedproc_sql
     
  end

  def self.down
    execute "DROP PROCEDURE IF EXISTS reallocate_seats"
  end
end
