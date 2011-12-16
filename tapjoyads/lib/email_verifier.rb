class EmailVerifier

  FIELDS_TO_CHECK = %w(to cc bcc)

  def self.check_recipients(mail)
    FIELDS_TO_CHECK.each do |field|
      if mail.send(field).present?
        mail.send("#{field}=", mail.send(field).reject { |email| !Resolv.valid_email?(email) })
      end
    end

    if mail.to.blank?
      failed_email = FailedEmail.new
      failed_email.fill(mail)
      failed_email.serial_save
    end

    mail.to.present?
  end

end
