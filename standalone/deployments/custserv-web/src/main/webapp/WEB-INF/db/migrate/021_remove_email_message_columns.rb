class RemoveEmailMessageColumns < ActiveRecord::Migration
  def self.up
    remove_column :email_message, :org_id
    remove_column :email_message, :sam_server_school_info_id
  end

  def self.down
    add_column :email_message, :org_id, :integer, :null => true, :references => :org
    add_column :email_message, :sam_server_school_info_id, :integer, :null => true, :references => :sam_server_school_info
  end
end
