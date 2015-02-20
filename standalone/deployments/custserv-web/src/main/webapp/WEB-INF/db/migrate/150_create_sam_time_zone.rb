class CreateSamTimeZone < ActiveRecord::Migration
  def self.up
    create_table :sam_time_zone do |t|
      t.column "time_zone_name",  :string
    end
  end

  def self.down
    drop_table :sam_time_zone
  end
end
