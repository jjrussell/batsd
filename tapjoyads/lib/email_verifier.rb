class EmailVerifier

  RECIPIENT_FIELDS = %w(to cc bcc)

  def self.check_recipients(mail)
    failed_email = FailedEmail.new(:load => false)
    failed_email.fill(mail)

    RECIPIENT_FIELDS.each do |field|
      if mail.send(field).present?
        mail.send("#{field}=", mail.send(field).reject { |email| !Resolv.valid_email?(email) })
      end
    end

    if mail.to.blank?
      failed_email.serial_save
      Notifier.alert_new_relic(EmailVerificationFailure, "To: #{failed_email.to}. FailedEmail id: #{failed_email.id}")
    end

    mail.to.present?
  end

end
