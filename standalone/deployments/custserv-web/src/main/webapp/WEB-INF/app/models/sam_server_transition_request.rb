class SamServerTransitionRequest < ActiveRecord::Base
  
  # object representing a request made by a SAMC user to have a server deactivated or some other
  # action performed. this request is mapped to the server and can be completed or revoked by 
  # a higher-permissions SAMC user.
  
  set_table_name "sam_server_transition_request"
  
  belongs_to :sam_server
  belongs_to :user
  
  @@STATUS_PENDING = 'p'
  @@STATUS_COMPLETE = 'c'
  @@STATUS_CANCELLED = 'x'
  @@STATUS_REVOKED = 'r'
  
  @@DEACTIVATION_CODE = 'SSD'
  #@@MOVE_CODE = 'SSM'  maybe in the future  
  
  def SamServerTransitionRequest.STATUS_PENDING
    return @@STATUS_PENDING
  end
  
  def SamServerTransitionRequest.STATUS_COMPLETE
    return @@STATUS_COMPLETE
  end
  
  def SamServerTransitionRequest.STATUS_CANCELLED
    return @@STATUS_CANCELLED
  end
  
  def SamServerTransitionRequest.STATUS_REVOKED
    return @@STATUS_REVOKED
  end
  
  def SamServerTransitionRequest.DEACTIVATION_CODE
    return @@DEACTIVATION_CODE
  end
  
  
  def cancel
    self.status = @@STATUS_CANCELLED
  end
  
  
  def revoke
    self.status = @@STATUS_REVOKED
  end
  
end