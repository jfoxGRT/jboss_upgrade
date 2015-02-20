class SnapshotServerLicenseCount < ActiveRecord::Base
  set_table_name "snapshot_server_license_counts"
  belongs_to :sam_server
  belongs_to :subcommunity
 
  @@INITIAL_REGISTRATION_CODE = "r"
  @@INITIAL_LICENSING_ACTIVATION_CODE = "a"
  @@LICENSE_SYNCING = "s"
  @@PRE_INSTALLATION_CODE_CHANGE_CODE = "i"
  @@POST_INSTALLATION_CODE_CHANGE_CODE = "j"
  
  def self.INITIAL_REGISTRATION_CODE
    @@INITIAL_REGISTRATION_CODE
  end
  
  def self.INITIAL_LICENSING_ACTIVATION_CODE
    @@INITIAL_LICENSING_ACTIVATION_CODE
  end
  
  def self.LICENSE_SYNCING_CODE
    @@LICENSE_SYNCING_CODE
  end
  
  def self.PRE_INSTALLATION_CODE_CHANGE_CODE
    @@PRE_INSTALLATION_CODE_CHANGE_CODE
  end
  
  def self.POST_INSTALLATION_CODE_CHANGE_CODE
    @@POST_INSTALLATION_CODE_CHANGE_CODE
  end
  
end

# == Schema Information
#
# Table name: snapshot_server_license_counts
#
#  id                :integer(10)     not null, primary key
#  created_at        :datetime        not null
#  event_type        :string(1)       not null
#  sam_server_id     :integer(10)
#  subcommunity_id   :integer(10)     not null
#  licensed_seats    :integer(10)
#  used_seats        :integer(10)
#  sam_customer_id   :integer(10)
#  seat_pool_count   :integer(10)
#  entitlement_count :integer(10)
#

