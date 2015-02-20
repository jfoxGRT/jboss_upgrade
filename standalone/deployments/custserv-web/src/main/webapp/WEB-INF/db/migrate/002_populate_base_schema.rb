require 'faster_csv'

class PopulateBaseSchema < ActiveRecord::Migration
  def self.up
    down
    
    directory = File.join(File.dirname(__FILE__), "ref" )

    FasterCSV.foreach(File.join( directory, "customer_group.csv" ) ) do |row|
      ref = CustomerGroup.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "customer_type.csv" ) ) do |row|
      ref = CustomerType.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "customer_status.csv" ) ) do |row|
      ref = CustomerStatus.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "relationship_type.csv" ) ) do |row|
      ref = RelationshipType.create(:code => row[0], :description => row[1], :text => row[2] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "relationship_category.csv" ) ) do |row|
      ref = RelationshipCategory.create(:code => row[0], :description => row[1], :text => row[2] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "role_group.csv" ) ) do |row|
      ref = RoleGroup.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "role_type.csv" ) ) do |row|
      ref = RoleType.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "address_type.csv" ) ) do |row|
      ref = AddressType.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "deliv_status.csv" ) ) do |row|
      ref = DelivStatus.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "email_address_type.csv" ) ) do |row|
      ref = EmailAddressType.create(:code => row[0], :description => row[1], :text => row[2] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "source_system.csv" ) ) do |row|
      ref = SourceSystem.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "auth_src_verified.csv" ) ) do |row|
      ref = AuthSrcVerified.create(:code => row[0], :description => row[1], :text => row[2] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "license_portability.csv" ) ) do |row|
      ref = LicensePortability.create(:code => row[0], :description => row[1])
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "collection_method.csv" ) ) do |row|
      ref = CollectionMethod.create(:code => row[0], :description => row[1])
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "telephone_type.csv" ) ) do |row|
      ref = TelephoneType.create(:code => row[0], :customer_classification_indicator => row[1], :description => row[2], :text => row[3])
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "response_code.csv" ) ) do |row|
      ref = ResponseCode.create(:code => row[0], :description => row[1])
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "conversation_result_type.csv" ) ) do |row|
      ref = ConversationResultType.create(:code => row[0], :name => row[1])
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "public_private.csv" ) ) do |row|
      ref = PublicPrivate.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "religious_affiliation.csv" ) ) do |row|
      ref = ReligiousAffiliation.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "usps_record_type.csv" ) ) do |row|
      ref = UspsRecordType.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "license_duration.csv" ) ) do |row|
      ref = LicenseDuration.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "grace_period.csv" ) ) do |row|
      ref = GracePeriod.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "entitlement_org_type.csv" ) ) do |row|
      ref = EntitlementOrgType.create(:code => row[0], :description => row[1] )
      ref.save!
    end
    
    FasterCSV.foreach(File.join( directory, "license_count_type.csv" ) ) do |row|
      ref = LicenseCountType.create(:code => row[0], :description => row[1] )
      ref.save!
    end
    
    FasterCSV.foreach(File.join( directory, "community.csv" ) ) do |row|
      ref = Community.create(:code => row[0], :name => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "country.csv" ) ) do |row|
      ref = Country.create(:code => row[0], :iso_code => row[1], :name => row[2] )
      ref.save!
    end
    
    FasterCSV.foreach(File.join( directory, "state_province.csv" ) ) do |row|
      ref = StateProvince.create(:code => row[0], :country => Country.find_by_iso_code( row[1] ), :name => row[2] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "salutation.csv" ) ) do |row|
      ref = Salutation.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "suffix.csv" ) ) do |row|
      ref = Suffix.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "seat_status.csv" ) ) do |row|
      ref = SeatStatus.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "sc_entitlement_type.csv" ) ) do |row|
      ref = ScEntitlementType.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "product_group.csv" ) ) do |row|
      ref = ProductGroup.create(:code => row[0], :description => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "product.csv" ) ) do |row|
      ref = Product.create(:id_provider => row[0], :id_value => row[1], :description => row[2], :product_group => ProductGroup.find_by_code( row[3] ) )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "subcommunity.csv" ) ) do |row|
      if( row[1].to_i == -1 )
        ref = Subcommunity.create(:community => Community.find_by_code( row[0] ), :name => row[2], 
                                  :code => row[3], :license_seed_code => row[4], :suppress_entitlement_update => row[5])
        ref.save!
      else
        ref = Subcommunity.create(:community => Community.find_by_code( row[0] ), :product => Product.find_by_id_value(row[1]), :name => row[2], 
                                  :code => row[3], :license_seed_code => row[4], :suppress_entitlement_update => row[5] )
        ref.save!
      end
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "item.csv" ) ) do |row|
      ref = Item.create(:item_num => row[0], :description => row[1], :item_type => row[2], :licenses => row[4] )
      ref.save!
    end

    # Populate Default for Product on Item
    #FasterCSV.foreach(File.join( directory, "item.csv" ) ) do |row|
    #  if(row[5])
    #    item = Item.find(:first, :conditions => ["item_num = ?", row[0]])
    #    item.default_for_product = row[5]
    #    item.save!
    #  end
    #end

    FasterCSV.foreach(File.join( directory, "role.csv" ) ) do |row|
      ref = Role.create(:code => row[0], :name => row[1] )
      ref.save!
    end

    FasterCSV.foreach(File.join( directory, "permission.csv" ) ) do |row|
      ref = Permission.create(:code => row[0], :name => row[1], :role => Role.find( row[2] ) )
      ref.save!
    end    
end
  
  def self.down
    Permission.delete_all
    Role.delete_all
    Item.delete_all
    Subcommunity.delete_all
    Product.delete_all
    ProductGroup.delete_all
    ScEntitlementType.delete_all
    SeatStatus.delete_all
    Suffix.delete_all
    Salutation.delete_all
    StateProvince.delete_all
    Country.delete_all
    Community.delete_all
    LicenseCountType.delete_all
    EntitlementOrgType.delete_all
    GracePeriod.delete_all
    LicenseDuration.delete_all
    UspsRecordType.delete_all
    ReligiousAffiliation.delete_all
    PublicPrivate.delete_all
    ConversationResultType.delete_all
    ResponseCode.delete_all
    TelephoneType.delete_all
    CollectionMethod.delete_all
    LicensePortability.delete_all
    AuthSrcVerified.delete_all
    SourceSystem.delete_all
    EmailAddressType.delete_all
    DelivStatus.delete_all
    AddressType.delete_all
    RoleType.delete_all
    RoleGroup.delete_all
    RelationshipCategory.delete_all
    RelationshipType.delete_all
    CustomerStatus.delete_all
    CustomerType.delete_all
    CustomerGroup.delete_all
  end
end
