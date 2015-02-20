class Telephone < ActiveRecord::Base
  set_table_name "telephone"
  belongs_to :customer
  belongs_to :telephone_type
end

# == Schema Information
#
# Table name: telephone
#
#  id                             :integer(10)     not null, primary key
#  customer_id                    :integer(10)
#  telephone_type_id              :integer(10)
#  telephone_number               :string(255)
#  telephone_extension_number     :string(15)
#  effective_date                 :datetime
#  fax_authorization_indicator    :string(255)
#  fax_authorization_last_name    :string(255)
#  fax_authorization_first_name   :string(255)
#  fax_authorization_job_title    :string(255)
#  fax_authorization_date         :datetime
#  fax_authorization_text         :string(255)
#  domestic_indicator             :string(255)
#  last_contact_date              :datetime
#  response_code_id               :integer(10)
#  state_dncl_indicator           :string(255)
#  state_dncl_update_date         :datetime
#  federal_dncl_indicator         :string(255)
#  federal_dncl_update_date       :datetime
#  collection_method_id           :integer(10)
#  last_acknowledged_date         :datetime
#  enterprise_telephone_indicator :string(255)
#

