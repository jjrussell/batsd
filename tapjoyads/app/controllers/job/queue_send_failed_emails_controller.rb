class Job::QueueSendFailedEmailsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::FAILED_EMAILS
  end
  
  private
  
  def on_message(message)
    mail = Marshal.restore(Base64::decode64(message.to_s))
    ActionMailer::Base.deliver_without_rescue_errors(mail)
  end
  
end
