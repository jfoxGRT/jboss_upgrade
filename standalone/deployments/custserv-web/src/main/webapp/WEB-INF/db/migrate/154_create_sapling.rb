class CreateSapling < ActiveRecord::Migration
  def self.up
    create_table :sapling do |t|
      t.column "created_at",  :datetime, :null => false
      t.column "updated_at",  :datetime
      t.column "published_at",  :datetime
      t.column "sapling_code", :string, :null => false
      t.column "type", :string, :null => false
      t.column "version", :integer, :null => false
      t.column "os_family", :string, :null => false
      t.column "os_series", :string, :null => false
      t.column "cpu_type", :string, :null => false
      t.column "cpu_bits", :string, :null => false
      t.column "scheduled", :boolean, :null => false
    end
  end

  def self.down
    drop_table :sapling
  end
end
