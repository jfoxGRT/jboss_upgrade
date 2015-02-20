class CreateSaplingMeta < ActiveRecord::Migration
  def self.up
    create_table :sapling_meta do |t|
      t.column "sapling_id", :integer, :null => false, :references => :sapling
      t.column "name", :string, :null => false
      t.column "value", :string
    end
  end

  def self.down
    drop_table :sapling_meta
  end
end
