class AddMergeToIdColumn < ActiveRecord::Migration
  def self.up
    add_column :customer, :id_merge_to, :integer, :null => true
  end

  def self.down
    remove_column :customer, :id_merge_to
  end
end
