class AddCorpIdColumn < ActiveRecord::Migration
  def self.up
    add_column :esb_message, :corpid_value, :string, :null => true
  end

  def self.down
    remove_column :esb_message, :corpid_value
  end
end
