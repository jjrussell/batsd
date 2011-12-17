class Resolv

  WHITELISTED_MX_DOMAINS = %w(
    tapjoy.com
    hotmail.com
    yahoo.com
    gmail.com
    aol.com
    hotmail.co.uk
    live.com
    naver.com
    qq.com
    hotmail.fr
    ymail.com
    163.com
    mail.ru
    msn.com
    yahoo.com.hk
    yahoo.com.tw
    hanmail.net
    nate.com
    yahoo.co.uk
    aim.com
    comcast.net
  )

  def self.valid_email?(email)
    domain = email.gsub(/^.+\@/, '')
    return true if WHITELISTED_MX_DOMAINS.include?(domain)
    mx_recs = self::DNS.open { |dns| dns.getresources(domain, Resolv::DNS::Resource::IN::MX) }
    mx_recs.reject { |mx_rec| mx_rec.exchange.to_s.strip.blank? }.any?
  rescue
    true
  end

end
