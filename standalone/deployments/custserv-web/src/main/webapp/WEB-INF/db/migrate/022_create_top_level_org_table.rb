class CreateTopLevelOrgTable < ActiveRecord::Migration
  def self.up
    create_table "top_level_org", :force => true do |t|
      t.column "org_id", :integer, :null => false, :references => :org
      t.column "top_level_org_id", :integer, :references => :org
    end
  end

  def self.down
    drop_table :top_level_org
  end
end
