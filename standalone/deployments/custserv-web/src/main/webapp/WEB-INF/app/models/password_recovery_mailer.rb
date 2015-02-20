class PasswordRecoveryMailer < ActionMailer::Base
  def forgot(user, new_password)
    @subject = "Your SAM Connect Password"
    @body["user"] = user
    @body["new_password"] = new_password
    @recipients = user.email  
    # TODO: This email address must be changed
    @from = 'tobrien@grtmail.com'
    @sent_on = Time.new
    @headers = {}
  end

end
