class AlertParam < ActiveRecord::Base
  belongs_to :alert_instance
  
  @@EVENT_TYPE = 'eventType'

  def self.EVENT_TYPE
    @@EVENT_TYPE
  end
  
end
# == Schema Information
#
# Table name: alert_params
#
#  id                :integer(10)     not null, primary key
#  alert_instance_id :integer(10)     not null
#  name              :string(255)     not null
#  value             :string(255)
#

