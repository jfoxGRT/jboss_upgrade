class InsertTopLevelOrgRecord < ActiveRecord::Migration
  def self.up
  
    Org.delete_all()
    Customer.delete_all()
  
    closedStatus = CustomerStatus.find_by_code( "02" )
    unknownType = CustomerType.find_by_code( "UNK" )
    unknownGrp = CustomerGroup.find_by_code( "UNK")
    topLevelCustomer = Customer.new( :ucn => "-1", :customer_group => unknownGrp, :customer_type => unknownType, :customer_status => closedStatus )
    topLevelCustomer.save!
    
    topLevelOrg = Org.new( :customer => topLevelCustomer, :name => "_SC_INTERNAL - TOP-LEVEL ORGANIZATION")
    topLevelOrg.save!
  end

  def self.down
  end
end
