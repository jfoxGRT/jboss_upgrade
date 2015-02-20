class RenameClassColumn < ActiveRecord::Migration
  def self.up
    rename_column :audit_message, :class, :clazz
  end

  def self.down
    rename_column :audit_message, :clazz, :class
  end
end
