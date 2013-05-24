class ServerWhitelist
  SERVER_IP_WHITELIST = [
    '38.104.224.62',                         # Tapjoy SF added 2012.06.04
    '38.104.183.198',                        # Tapjoy Atlanta added 2012.06.04
    '212.36.48.233',                         # Tapjoy London added 2012.06.06
    ['173.166.99.161', '173.166.99.177'],    # Tapjoy Boston added 2012.08.30
    '23.22.121.11',                          # Tapjoy dashboard server added 2012.10.12
    '54.242.78.135',                         # Tapjoy dashboard server added 2012.10.12
    '174.129.83.90',                         # Tapjoy dashboard server added 2012.10.12
    '50.17.66.224',                          # Tapjoy dashboard server added 2012.10.12
    '50.19.206.168',                         # Tapjoy dashboard server added 2012.12.10
    '184.170.255.101',                       # Tapjoy support server added 2012.08.01
    ['193.169.104.246', '193.169.104.248'],  # Adperio added 2012.05.22
    ['193.169.105.246', '193.169.105.248'],  # Adperio added 2012.05.22
    '209.120.212.22',                        # Adperio added 2012.05.22
    '67.23.32.217',                          # Social Growth Tech added 2012.05.22
    ['184.173.90.58', '184.173.90.59'],      # Social Growth Tech added 2012.05.22
    '50.97.72.62',                           # Social Growth Tech added 2012.05.22
    '173.230.146.31',                        # Commission Junction added 2012.05.22
    ['173.255.223.74', '173.255.223.192'],   # Commission Junction added 2012.05.22
    '67.21.0.30',                            # Commission Junction added 2012.05.22
    ['67.21.4.132', '67.21.4.134'],          # Commission Junction added 2012.05.22
    '97.107.138.75',                         # Commission Junction added 2012.05.22
    ['63.215.202.0', '63.215.202.255'],      # Commission Junction added 2012.05.22, updated 2012.10.24
    '209.234.184.1',                         # Commission Junction added 2012.05.22
    ['216.34.207.0', '216.34.207.255'],      # Commission Junction added 2012.05.22, updated 2012.10.24
    ['64.70.54.0', '64.70.54.255'],          # Commission Junction added 2012.08.13, updated 2012.10.24
    ['64.70.58.0', '64.70.58.255'],          # Commission Junction added 2012.10.24
    ['8.18.45.0', '8.18.45.255'],            # Commission Junction added 2012.10.24
    '174.129.30.101',                        # HasOffers US East added 2012.05.22
    '50.16.235.30',                          # HasOffers US East added 2012.05.22
    '75.101.156.191',                        # HasOffers US East added 2012.05.22
    ['107.20.179.12', '107.20.179.123'],     # HasOffers US East added 2012.05.22
    '107.20.180.129',                        # HasOffers US East added 2012.05.22
    ['23.21.119.172', '23.21.119.198'],      # HasOffers US East added 2012.05.22
    '50.18.109.195',                         # HasOffers US West added 2012.05.22
    '50.18.126.93',                          # HasOffers US West added 2012.05.22
    '204.236.132.58',                        # HasOffers US West added 2012.05.22
    '50.18.155.149',                         # HasOffers US West added 2012.05.22
    ['50.18.156.14', '50.18.156.78'],        # HasOffers US West added 2012.05.22
    '79.125.116.52',                         # HasOffers Europe added 2012.05.22
    '79.125.110.249',                        # HasOffers Europe added 2012.05.22
    '46.51.190.241',                         # HasOffers Europe added 2012.05.22
    '46.51.183.234',                         # HasOffers Europe added 2012.05.22
    '46.137.109.19',                         # HasOffers Europe added 2012.05.22
    '46.137.87.162',                         # HasOffers Europe added 2012.05.22
    '79.125.122.234',                        # HasOffers Europe added 2012.05.22
    ['176.34.107.49', '176.34.107.63'],      # HasOffers Europe added 2012.05.22
    ['64.8.20.35', '64.8.20.36'],            # Websponsors added 2012.05.24
    ['69.25.171.0', '69.25.171.127'],        # Impact Radius added 2012.06.18
    ['50.56.137.44', '50.56.137.45'],        # Lucky Pacific added 2012.07.10
    ['50.56.42.244', '50.56.42.245'],        # Lucky Pacific added 2012.07.10
    ['184.106.48.88', '184.106.48.89'],      # Lucky Pacific added 2012.07.10
    ['184.106.88.64', '184.106.88.65'],      # Lucky Pacific added 2012.07.10
    '50.16.235.141',                         # Ring Revenue added 2012.08.02
    ['66.171.190.226', '66.171.190.231'],    # QuoteWizard added 2012.08.10
    ['209.63.198.242', '209.63.198.245'],    # QuoteWizard added 2012.08.10
    ['173.203.168.128', '173.203.168.138'],  # QuoteWizard added 2012.08.10, updated 2012.09.14
    '216.246.74.21',                         # DiscountMags added 2012.08.20
    '204.93.181.78',                         # DiscountMags added 2012.08.20
    '64.91.230.220',                         # ExclusiveCPA LLC added 2012.08.20
    '75.126.60.79',                          # Incentivize added 2013.01.02
    '50.22.127.199',                         # Incentivize added 2013.01.02
  ]

  def self.ip_whitelist_includes?(ip_address)
    get_whitelist_ips.any? do |entry|
      if entry.is_a? Array
        (entry[0].ip_to_i..entry[1].ip_to_i).include?(ip_address.ip_to_i)
      else
        entry == ip_address
      end
    end
  end

  private

  def self.get_whitelist_ips
    SERVER_IP_WHITELIST
  end
end
