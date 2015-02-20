class AddFakeCustomerRecords < ActiveRecord::Migration
  def self.up
  
    districtCustomerGroup = CustomerGroup.find_by_code("D")
    districtCustomerType = CustomerType.find_by_code("ADM")
    openStatus = CustomerStatus.find_by_code("01")
    internalOrg = Customer.find(:first, :conditions => ["ucn = -1"]).org
    addressType = AddressType.find_by_code("06")
    state = StateProvince.find_by_code("DC")
    theCountry = Country.find_by_code("US")
      
    fakeCustomer = Customer.new(:ucn => "-2", :customer_group => districtCustomerGroup, :customer_type => districtCustomerType, :customer_status => openStatus)
    fakeCustomer.save!
    
    fakeCustomerAddress = CustomerAddress.new(:customer => fakeCustomer, :address_type => addressType, :address_line_1 => "zzz_fake address_zzz", :city_name => "zzz_fake city_zzz",
              :state_province => state, :postal_code => "00000", :country => theCountry, :effective_date => Time.now)
    fakeCustomerAddress.save!
    
    fakeOrg = Org.new(:customer => fakeCustomer, :name => "zzz_FAKE SAM CONNECT CUSTOMER_zzz")
    fakeOrg.save!
    
    fakeTopLevelOrg = TopLevelOrg.new(:org => fakeOrg, :top_level_org => internalOrg)
    fakeTopLevelOrg.save!
    
    fakeSamCustomer = SamCustomer.new(:root_org => fakeOrg, :fake => true)
    fakeSamCustomer.save!
  
  end

  def self.down
  end
  
end
