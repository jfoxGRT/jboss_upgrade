class CreateEmailTypeTable < ActiveRecord::Migration
  def self.up
    create_table "email_type", :force => true do |t|
    t.column "code",                      :string,   :limit => 40
    t.column "description",               :string
    end
  end

  def self.down
    drop_table :email_type
  end
end
