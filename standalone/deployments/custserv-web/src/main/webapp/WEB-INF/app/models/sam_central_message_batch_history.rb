
class SamCentralMessageBatchHistory < ActiveRecord::Base
  set_table_name "sam_central_message_batch_history"
  
  # average processing time for a batch of messages from a given queue, in seconds
  def self.get_average_batch_time_for_queue(queue_name)
    average_batch_time = self.average('UNIX_TIMESTAMP(created_at) - UNIX_TIMESTAMP(batch_start)', :conditions=> "queue_name = '#{queue_name}'")
    (average_batch_time ||= 0.0).round(1)
  end
  
  
  def self.get_reporting_history_for_queue(queue_name) # queue_name input required, we're only grouping by time period
    sql = <<EOS
      SELECT ROUND(60*60*(AVG(batch_size)/AVG(UNIX_TIMESTAMP(created_at) - UNIX_TIMESTAMP(batch_start))), 0) AS avg_messages_per_hour, LEFT(created_at,13) AS hour 
      FROM sam_central_message_batch_history 
      WHERE queue_name = '#{queue_name}' GROUP BY hour
EOS
    
    available_history_records = find_by_sql(sql)
    
    if(available_history_records && !available_history_records.empty?)
      #logger.debug "available_history_records = #{available_history_records.to_yaml}"
      
      # convert array of activerecords to array of hashes
      # TODO: better way to do this
      available_history_hashes = Array.new
      available_history_records.each do |available_history_record|
        available_history_hashes << available_history_record.attributes
      end
      #logger.debug "available_history_hashes = #{available_history_hashes.to_yaml}"
      
      empty_time_window_fillins = get_empty_time_window_fillins(available_history_records.first.hour)
      #logger.debug "empty_time_window_fillins = #{empty_time_window_fillins.to_yaml}"
      
      reporting_history = merge_batch_history_with_fillins(available_history_hashes, empty_time_window_fillins)
    else
      logger.info "available_history_records was null or empty"
      reporting_history = Array.new
    end
    #logger.debug "reporting_history = #{reporting_history.to_yaml}"
    return reporting_history # an array of hashes
  end
  
  # starting with the provided date (earliest applicable sam_central_message_batch_history record), increment
  # forward to current time, building an array of hashes with hourly keys and values of 0
  def self.get_empty_time_window_fillins(start_time_string)
    tracking_timesamp = Time.parse(start_time_string)
    end_time = Time.now
    
    get_empty_time_window_fillins = Array.new
    while tracking_timesamp < end_time
      formatted_timestamp_string = tracking_timesamp.strftime("%Y-%m-%d %H")
      get_empty_time_window_fillins << {:hour => formatted_timestamp_string, :avg_messages_per_hour => 0}
      tracking_timesamp += 60*60 # add one hour (3600 secs) for next loop
    end
    
    return get_empty_time_window_fillins
  end
  
  
  # merge two arrays of hashes:
  #   batch_history_array has good data but not all keys
  #   fillins_array has all the keys but no real data
  def self.merge_batch_history_with_fillins(batch_history_array, fillins_array)
    result_array = fillins_array
    result_array.each do |result_hash|
      key = result_hash[:hour]
      batch_history_array.each do |batch_history_hash|
        if key == batch_history_hash['hour']
          result_hash[:avg_messages_per_hour] = batch_history_hash['avg_messages_per_hour']
          break
        end
      end
    end
    
    return result_array
  end
  
end
