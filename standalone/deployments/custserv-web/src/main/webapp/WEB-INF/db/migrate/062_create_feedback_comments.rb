class CreateFeedbackComments < ActiveRecord::Migration
  def self.up
    create_table "feedback_comments", :force => true do |t|
      t.column "created_at",      :datetime, :null => false
      t.column "user_id",         :integer, :null => false, :references => nil
      t.column "sam_customer_id", :integer, :null => false, :references => nil
      t.column "comment",         :text, :null => false
    end
  end

  def self.down
    drop_table :feedback_comments
  end
end
