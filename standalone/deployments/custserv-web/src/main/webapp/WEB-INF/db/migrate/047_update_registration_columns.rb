class UpdateRegistrationColumns < ActiveRecord::Migration
  def self.up
    rename_column :sam_customer, :sc_registration_date, :cutover_date
    add_column :sam_customer, :registration_date, :datetime, :null => true
  end

  def self.down
    rename_column :sam_customer, :cutover_date, :sc_registration_date
    remove_column :sam_customer, :registration_date
  end
end
