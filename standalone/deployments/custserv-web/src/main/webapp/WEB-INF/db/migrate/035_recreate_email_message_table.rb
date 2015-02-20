class RecreateEmailMessageTable < ActiveRecord::Migration
  def self.up
    drop_table :email_message
    create_table :email_message, :force => true do |t|
      t.column :email_type_id,             :integer,  :null => false, :references => :email_type
      # user_id is intentionally not a foreign key (users could be deleted)
      t.column :user_id,                   :integer,  :null => false, :references => nil
      t.column :recipient_address,         :string,   :null => false
      t.column :subject,                   :string,   :null => false
      t.column :text_body,                 :text,     :null => false
      t.column :html_body,                 :text,     :null => false
      t.column :generated_date,            :datetime, :null => false
      t.column :approved_date,             :datetime, :null => true
      t.column :sent_date,                 :datetime, :null => true
    end
  end

  def self.down
  end
end
