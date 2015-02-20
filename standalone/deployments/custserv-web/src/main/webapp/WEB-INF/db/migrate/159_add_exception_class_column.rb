class AddExceptionClassColumn < ActiveRecord::Migration
  def self.up
    add_column :esb_message, :exception_class, :string, :null => true
  end

  def self.down
    remove_column :esb_message, :exception_class
  end
end
