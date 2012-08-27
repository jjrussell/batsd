class Linkshare

# Syntax for various affiliates:
# http://www.apple.com/itunes/affiliates/resources/documentation/linking-to-the-itunes-music-store.html
# TradeDoubler: partnerId=2003&tduid=
# Linkshare:    partnerId=30&siteID=
# DGM:          partnerId=1002&affToken=
  REGION_TOKENS = {
    'AR' => 'partnerId=2003&tduid=AR2145609',
    'BR' => 'partnerId=2003&tduid=BR2145607',
    'GB' => 'partnerId=2003&tduid=GB2079767',
    'UK' => 'partnerId=2003&tduid=UK2145605',
    'BE' => 'partnerId=2003&tduid=BE2081187',
    'BR' => 'partnerId=2003&tduid=BR2081199',
    'CH' => 'partnerId=2003&tduid=CH2081198',
    'DE' => 'partnerId=2003&tduid=DE2145621',
    'ES' => 'partnerId=2003&tduid=ES2081197',
    'FR' => 'partnerId=2003&tduid=FR2081184',
    'IE' => 'partnerId=2003&tduid=IE2081195',
    'IT' => 'partnerId=2003&tduid=IT2081189',
    'NL' => 'partnerId=2003&tduid=NL2081194',
    'SE' => 'partnerId=2003&tduid=SE2081185',
    'JP' => 'partnerId=30&siteID=Qr66oOu*yBY',
    'US' => 'partnerId=30&siteID=OxXMC6MRBt4',
    'CA' => 'partnerId=30&siteID=OxXMC6MRBt4',
    'NZ' => 'partnerId=1002&affToken=37022',
    'AU' => 'partnerId=1002&affToken=37022',
  }

  def self.add_params(url, itunes_link_affiliate = nil)
    itunes_link_affiliate ||= 'partnerId=30&siteID=OxXMC6MRBt4'

    if url =~ /^http:\/\/itunes\.apple\.com/
      separator = url =~ /\?/ ? '&' : '?'
      "#{url}#{separator}#{itunes_link_affiliate}"
    else
      url
    end
  end

  def self.affiliate_token(country)
    REGION_TOKENS[country.to_s.upcase]
  end
end
