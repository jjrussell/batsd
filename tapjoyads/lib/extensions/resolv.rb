class Resolv

  WHITELISTED_MX_DOMAINS = %w(
    tapjoy.com
    gmail.com
    aol.com
    hotmail.com
    yahoo.com
  )

  def self.valid_email?(email)
    domain = email.gsub(/^.+\@/, '')
    WHITELISTED_MX_DOMAINS.include?(domain) || self::DNS.open { |dns| dns.getresources(domain, Resolv::DNS::Resource::IN::MX) }.any?
  end

end
