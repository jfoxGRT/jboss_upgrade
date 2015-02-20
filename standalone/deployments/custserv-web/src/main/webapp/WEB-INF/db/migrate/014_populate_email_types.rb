class PopulateEmailTypes < ActiveRecord::Migration
  def self.up
    welcome = EmailType.new(:code => "01", :description => "Welcome")
    welcome.save!
    newlicenses = EmailType.new(:code => "02", :description => "New Licenses")
    newlicenses.save!
  end

  def self.down
  end
end
