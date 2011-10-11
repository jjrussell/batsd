class FailedEmail < SimpledbResource

  self.domain_name = 'failed_emails'

  self.sdb_attr :to
  self.sdb_attr :from
  self.sdb_attr :cc
  self.sdb_attr :bcc
  self.sdb_attr :subject
  self.sdb_attr :serialized_email

  def fill(mail)
    self.to               = mail.to
    self.from             = mail.from
    self.cc               = mail.cc
    self.bcc              = mail.bcc
    self.subject          = mail.subject
    self.serialized_email = Base64::encode64(Marshal.dump(mail))
  end

end
