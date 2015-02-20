class AddScLicensingActivated < ActiveRecord::Migration
  def self.up
    add_column(:sam_customer, :sc_licensing_activated, :datetime, :null => true)
  end

  def self.down
    remove_column(:sam_customer, :sc_licensing_activated)
  end
end
