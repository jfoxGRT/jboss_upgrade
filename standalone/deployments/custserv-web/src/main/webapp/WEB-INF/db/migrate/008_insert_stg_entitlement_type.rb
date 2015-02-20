class InsertStgEntitlementType < ActiveRecord::Migration
  def self.up
    stgtype = EntitlementType.new(:code => "STG", :description => "Complete Set")
    stgtype.save!
  end

  def self.down
  end
end
