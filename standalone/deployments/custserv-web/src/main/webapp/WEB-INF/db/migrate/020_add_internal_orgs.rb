class AddInternalOrgs < ActiveRecord::Migration
  def self.up
  
    closedStatus = CustomerStatus.find_by_code( "02" )
    unknownType = CustomerType.find_by_code( "UNK" )
    unknownGrp = CustomerGroup.find_by_code( "UNK")
  
    voidCustomer = Customer.new( :ucn => "0", :customer_group => unknownGrp, :customer_type => unknownType, :customer_status => closedStatus )
    noOpenCustomer = Customer.new( :ucn => "-1", :customer_group => unknownGrp, :customer_type => unknownType, :customer_status => closedStatus )
    voidCustomer.save!
    noOpenCustomer.save!
  
    voidOrg = Org.new( :customer => voidCustomer, :name => "_SC_INTERNAL - MULTIPLE TOP-LEVEL ORGANIZATIONS")
    noOpenOrg = Org.new( :customer => noOpenCustomer, :name => "_SC_INTERNAL - NO OPEN TOP-LEVEL ORGANIZATIONS")
    voidOrg.save!
    noOpenOrg.save!
    
  end

  def self.down
  end
end
