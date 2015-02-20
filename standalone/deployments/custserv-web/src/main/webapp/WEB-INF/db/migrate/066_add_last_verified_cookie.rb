class AddLastVerifiedCookie < ActiveRecord::Migration
  def self.up
    add_column :agent, :last_verified_cookie, :string, :limit => 36, :null => true
    add_index "agent", ["last_verified_cookie"], :name => "last_verified_cookie", :unique => true
  end

  def self.down
    remove_index "agent", :name => "last_verified_cookie"
    remove_column :agent, :last_verified_cookie
  end
end
