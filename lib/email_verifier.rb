class EmailVerifier

  RECIPIENT_FIELDS = %w(to cc bcc)

  def self.check_recipients(mail)
    failed_email = FailedEmail.new(:load => false)
    failed_email.fill(mail)

    RECIPIENT_FIELDS.each do |field|
      existing_emails = mail.send(field)
      if existing_emails.present?
        approved_emails = []
        existing_emails.each do |email|
          if Resolv.valid_email?(email)
            approved_emails << email
          else
            Notifier.alert_new_relic(EmailVerificationFailure, "#{email} is not valid.")
          end
        end

        mail.send("#{field}=", approved_emails) if existing_emails.size != approved_emails.size
      end
    end

    if mail.to.blank?
      failed_email.save
      Notifier.alert_new_relic(EmailNotDelivered, "No message sent because 'To' is blank. FailedEmail id: #{failed_email.id}")
    end

    mail.to.present?
  end

end
