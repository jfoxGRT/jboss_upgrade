class SrcQuizPreferences < ActiveRecord::Base
  acts_as_cached
  set_table_name "src_quiz_preferences"
  
  def self.find_server_src_quiz_activation_dates(sam_customer_id)
    find(:all, :select => "sqp.activation_date as quiz_activation_date",
               :joins => "sqp inner join sam_server ss on sqp.sam_server_id = ss.id",
               :conditions => ["ss.sam_customer_id = ? and ss.status = 'a' and sqp.status='a' and (sqp.src_quiz_01 = 1 or sqp.src_quiz_02 = 1 or sqp.src_quiz_03 = 1 or sqp.src_quiz_04 = 1 or sqp.src_quiz_05 = 1)", sam_customer_id])
  end
end
# == Schema Information
#
# Table name: src_quiz_preferences
#
#  id              :integer(10)     not null, primary key
#  sam_server_id   :integer(10)     not null
#  src_quiz_01     :boolean
#  src_quiz_02     :boolean
#  src_quiz_03     :boolean
#  src_quiz_04     :boolean
#  src_quiz_05     :boolean
#  status          :string(1)       default("n"), not null
#  activation_date :datetime
#

