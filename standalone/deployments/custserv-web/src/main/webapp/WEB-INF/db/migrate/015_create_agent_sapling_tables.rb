class CreateAgentSaplingTables < ActiveRecord::Migration
  def self.up
    create_table "agent_sapling", :force => true do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "agent_id",   :integer,  :null => false, :references => :agent
      t.column "sapling_id", :string,   :null => false, :references => nil
      t.column "version",    :integer,  :null => false
      t.column "type",       :string,   :null => false
      t.column "os_series",  :string,   :null => false
      t.column "cpu_bits",   :string,   :null => false
      t.column "os_family",  :string,   :null => false
      t.column "cpu_type",   :string,   :null => false
    end
  end

  def self.down
    drop_table :agent_sapling
  end
end
