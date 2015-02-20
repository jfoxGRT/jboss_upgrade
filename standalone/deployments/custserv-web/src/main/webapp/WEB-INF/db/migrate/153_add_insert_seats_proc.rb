class AddInsertSeatsProc < ActiveRecord::Migration
  def self.up
    down
    
    @storedproc_sql=<<EOF
/**********************************************************************
 * Adds seats en masse.  This should be somewhat faster than doing the
 * same operation in java via hibernate.
 **********************************************************************/
CREATE PROCEDURE insert_seats(IN pNumSeats INT, IN pSamServerId INT, IN pSeatStatusId INT, IN pSeatBucketId INT)
BEGIN
  DECLARE curCount         INT DEFAULT 0;
  seatloop: LOOP
    IF curCount >= pNumSeats THEN
       LEAVE seatloop;
    ELSE
       INSERT INTO seat(sam_server_id,seat_status_id,updated_at,created_at,seat_bucket_id)
                 VALUES(pSamServerId,pSeatStatusId,now(),now(),pSeatBucketId);
       UPDATE seat set orig_seat_id=last_insert_id() where id = last_insert_id();
       SELECT curCount + 1 INTO curCount;
    END IF;
  END LOOP seatloop;
  select curCount;
END
EOF

    execute @storedproc_sql
  end

  def self.down
    execute "DROP PROCEDURE IF EXISTS insert_seats"
  end
end
