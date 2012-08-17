class Linkshare
  TRADEDOUBLER_COUNTRIES = Set.new(%w( AR BR GB UK BE BR CH DE ES FR IE IT NL SE ))
  LINKSHARE_COUNTRIES = Set.new(%w( JP CA ))
  DGM_COUNTRIES = Set.new(%w( NW AU ))

  TRADEDOUBLER_TOKENS = { 'AR' => 'AR2145609',
                          'BR' => 'BR2145607',
                          'GB' => 'GB2079767',
                          'UK' => 'UK2145605',
                          'BE' => 'BE2081187',
                          'BR' => 'BR2081199',
                          'CH' => 'CH2081198',
                          'DE' => 'DE2145621',
                          'ES' => 'ES2081197',
                          'FR' => 'FR2081184',
                          'IE' => 'IE2081195',
                          'IT' => 'IT2081189',
                          'NL' => 'NL2081194',
                          'SE' => 'SE2081185'}
  LINKSHARE_TOKENS =    { 'JP' => 'Qr66oOu*yBY',
                          'US' => 'OxXMC6MRBt4',
                          'CA' => 'OxXMC6MRBt4'}
  DGM_TOKENS =          { 'NW' => '37022',
                          'AU' => '37022'}

  def self.add_params(url, country = nil)
    if url =~ /^http:\/\/itunes\.apple\.com/
      if TRADEDOUBLER_COUNTRIES.include?(country)
        url_params = "partnerId=2003&tduid=#{App::TRADEDOUBLER_TOKENS[country.upcase]}"
      elsif LINKSHARE_COUNTRIES.include?(country)
        url_params = "partnerId=30&siteID=#{LINKSHARE_TOKENS[country.upcase]}"
      elsif DGM_COUNTRIES.include?(country)
        url_params = "partnerId=1002&affToken=#{DGM_TOKENS[country.upcase]}"
      end

      #if country is not in any of the above lists, do we default to a country?
      url += url =~ /^http:\/\/itunes\.apple\.com\/.*\?/ ? '&' + url_params : '?' + url_params unless url_params.nil?
    end
    url
  end
end
