class InsertSeatBalancePermission < ActiveRecord::Migration
  def self.up
    Permission.create(:code => "LICENSE_BALANCE", :name => "Balance Customer Licenses", :user_type => 's')
  end

  def self.down
  end
end
