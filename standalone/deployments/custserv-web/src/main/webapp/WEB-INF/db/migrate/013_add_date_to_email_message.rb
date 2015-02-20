class AddDateToEmailMessage < ActiveRecord::Migration
  def self.up
    add_column :email_message, :email_date, :datetime, :null => false
  end

  def self.down
    remove_column :email_message, :email_date
  end
end
