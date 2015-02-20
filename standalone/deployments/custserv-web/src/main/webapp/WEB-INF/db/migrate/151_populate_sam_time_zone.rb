require 'faster_csv'

class PopulateSamTimeZone < ActiveRecord::Migration
  def self.up
    down
    
    directory = File.join(File.dirname(__FILE__), "ref" )

    FasterCSV.foreach(File.join( directory, "sam_time_zone.csv" ) ) do |row|
      ref = SamTimeZone.create(:time_zone_name => row[0] )
      ref.save!
    end
  end
  
  def self.down
    SamTimeZone.delete_all
  end
end
