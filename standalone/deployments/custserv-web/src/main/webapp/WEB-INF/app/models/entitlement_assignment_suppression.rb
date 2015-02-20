class EntitlementAssignmentSuppression < ActiveRecord::Base
  set_table_name "entitlement_assignment_suppressions"
  belongs_to :org
  belongs_to :user
  
  def ucn
    if (self.org)
      self.org.customer.ucn
    else
      nil
    end
  end
  
  def ucn=(ucn)
    self.org = Org.find_by_ucn(ucn)
  end
  
  def self.find_by_ucn(ucn)
    org = Org.find_by_ucn(ucn)
    return org.entitlement_assignment_suppression if org
    return nil
  end
  
  def validate
    errors.add("Root Organization UCN", " is not valid") if org.nil?
  end
  
end

# == Schema Information
#
# Table name: entitlement_assignment_suppressions
#
#  id         :integer(10)     not null, primary key
#  org_id     :integer(10)     not null
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer(10)     not null
#

