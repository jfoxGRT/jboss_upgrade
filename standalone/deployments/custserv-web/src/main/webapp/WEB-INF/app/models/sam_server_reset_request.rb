class SamServerResetRequest < ActiveRecord::Base
  
  # object representing a request made by a SAMC user to have a server something reset in the SAM instance
  # via SAMC. for example, a request to reset the dadmin password on a SAM server would be represented
  # here, which Commander+Agent would act on.
  
  set_table_name "sam_server_reset_request"
  
  belongs_to :sam_server
  belongs_to :user
  
  @@STATUS_PENDING = 'p'
  @@STATUS_SUCCESS = 's'
  @@STATUS_FAILURE = 'f'
  @@STATUS_CANCELLED = 'x'
  
  @@DADMIN_PASSWORD_CODE = 'DADMIN_PASSWORD'
  @@HOSTED_TERMS_ACCEPTANCE_CODE = 'HOSTED_TERMS_ACCEPTANCE'
    
  
  def self.STATUS_PENDING
    return @@STATUS_PENDING
  end
  
  def self.STATUS_SUCCESS
    return @@STATUS_SUCCESS
  end
  
  def self.STATUS_FAILURE
    return @@STATUS_FAILURE
  end
  
  def self.STATUS_CANCELLED
    return @@STATUS_CANCELLED
  end
  
  def self.DADMIN_PASSWORD_CODE
    return @@DADMIN_PASSWORD_CODE
  end
  
  def self.HOSTED_TERMS_ACCEPTANCE_CODE
    return @@HOSTED_TERMS_ACCEPTANCE_CODE
  end
  
  
  def cancel
    self.status = @@STATUS_CANCELLED
    self.save!
  end
  
  
end