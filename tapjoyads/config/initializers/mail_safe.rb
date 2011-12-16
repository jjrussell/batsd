LITMUS_SPAM_ADDRESSES = %w(
  ml@ml.emailtests.com
  postini_2@postini-mailtest.com
  barracuda@barracuda.emailtests.com
  chkemltests@gapps.emailtests.com
  chkemltests@me.com
  chkemltests@sg.emailtests.com
  chkemltests@gmx.com
  chkemltests@hushmail.com
  chkemltests@fastmail.fm
  chkemltests@lycos.com
  chkemltests@mail.com
)
if defined?(MailSafe::Config)
  MailSafe::Config.internal_address_definition = /.*@(tapjoy|emailtests)\.com|#{LITMUS_SPAM_ADDRESSES.join('|')}/i
end
