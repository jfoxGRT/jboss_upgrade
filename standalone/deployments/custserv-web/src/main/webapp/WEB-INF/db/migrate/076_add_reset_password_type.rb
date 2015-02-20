class AddResetPasswordType < ActiveRecord::Migration
  def self.up
    EmailType.new(:code => "03", :description => "Reset Password").save!    
  end

  def self.down
    EmailType.find_by_code("03").destroy
  end
end
