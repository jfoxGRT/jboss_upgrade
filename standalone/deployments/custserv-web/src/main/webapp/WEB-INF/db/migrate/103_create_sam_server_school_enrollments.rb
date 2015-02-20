class CreateSamServerSchoolEnrollments < ActiveRecord::Migration
  def self.up
    create_table :sam_server_school_enrollments do |t|
      t.column "sam_server_school_info_id",  :integer, :null => false, :references => :sam_server_school_info
      t.column "subcommunity_id",            :integer, :null => false, :references => :subcommunity 
      t.column "enrolled",                   :integer
      t.column "allowed_max",                :integer
      t.column "allowed_max_from_noop",      :integer
    end
    
    execute "ALTER TABLE sam_server_school_enrollments ADD CONSTRAINT schoolenrollments_schoolinfo_subcom_unique UNIQUE (sam_server_school_info_id, subcommunity_id)"    

    add_column :sam_server, :enforce_school_max_enroll_cap, :boolean, :default => false
    
  end

  def self.down
    drop_table :sam_server_school_enrollments
    
    remove_column :sam_server, :enforce_school_max_enroll_cap
  end
end
