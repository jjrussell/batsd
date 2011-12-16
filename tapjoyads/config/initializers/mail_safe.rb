if defined?(MailSafe::Config)
  MailSafe::Config.internal_address_definition = /.*@(tapjoy|emailtests)\.com|#{LITMUS_SPAM_ADDRESSES.join('|')}/i
end
