class CreateEmailTable < ActiveRecord::Migration
  def self.up
    create_table "email_message", :force => true do |t|
      t.column "email_type_id",             :integer, :null => false, :default => 1, :references => :email_type
      t.column "org_id",                    :integer, :null => true, :references => :org
      t.column "sam_server_school_info_id", :integer, :null => true, :references => :sam_server_school_info
      t.column "subject",                   :string, :null => false
      t.column "body",                      :text, :null => true
    end
  end

  def self.down
    drop_table :email_message
  end
end
