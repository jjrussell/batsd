class AppStore

  ANDROID_APP_URL     = 'https://market.android.com/details?id='
  ANDROID_SEARCH_URL  = 'https://market.android.com/search?num=40&q='
  ITUNES_APP_URL      = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  ITUNES_SEARCH_URL   = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'
  WINDOWS_APP_URL     = 'http://catalog.zune.net/v3.2/en-US/apps/_APPID_?store=Zest&clientType=WinMobile+7.0'
  WINDOWS_SEARCH_URL  = 'http://catalog.zune.net/v3.2/en-US/?includeApplications=true&prefix='

  # NOTE: these numbers change every once in a while. Last update: 2011-08-11
  PRICE_TIERS = {
    'AUD' => [ 0.99, 1.99, 2.99, 4.49, 5.49 ],
    'CHF' => [ 0.65, 1.30, 1.94, 2.59, 3.24 ],
    'EUR' => [ 0.79, 1.59, 2.39, 2.99, 3.99 ],
    'GBP' => [ 0.69, 1.49, 1.99, 2.49, 2.99 ],
    'JPY' => [   85,  170,  250,  350,  450 ],
    'MXP' => [   12,   24,   36,   48,   60 ],
    'NOK' => [    7,   14,   21,   28,   35 ],
    'NZD' => [ 1.29, 2.59, 4.19, 5.29, 6.49 ],
  }

  APPSTORE_COUNTRIES = {
    :hk => "HK - Hong Kong",
    :il => "IL - Israel",
    :us => "US - United States",
    :br => "BR - Brazil",
    :tw => "TW - Taiwan",
    :it => "IT - Italy",
    :cn => "CN - China",
    :fr => "FR - France",
    :jp => "JP - Japan",
    :gb => "GB - United Kingdom",
    :ae => "AE - United Arab Emirates",
    :kr => "KR - Korea, Republic of",
    :ca => "CA - Canada",
    :mx => "MX - Mexico",
    :de => "DE - Germany",
    :es => "ES - Spain",
    :ru => "RU - Russian Federation",
    :au => "AU - Australia"
  }

  # returns hash of app info
  def self.fetch_app_by_id(id, platform, country='')
    case platform.downcase
    when 'android'
      self.fetch_app_by_id_for_android(id)
    when 'iphone'
      self.fetch_app_by_id_for_apple(id, country)
    when 'windows'
      self.fetch_app_by_id_for_windows(id)
    end
  end

  BLACKLISTABLE_COUNTRIES = ['US', 'GB', 'KR', 'CN', 'JP', 'TW', 'HK', 'FR', 'DE']
  def self.prepare_countries_blacklist(id, platform)
    case platform.downcase
    when 'iphone'
      list = []
      BLACKLISTABLE_COUNTRIES.each do |country|
        retries = 0
        begin
          results = self.fetch_app_by_id_for_apple(id, country)
          list << country if results.blank?
        rescue
          retries += 1
          retry if retries < 5
        end
      end
      list
    else
      [] # not supported
    end
  end

  # returns an array of first 24 App instances matching "term"
  def self.search(term, platform, country='')
    term = term.strip.gsub(/\s/, '+')
    case platform.downcase
    when 'android'
      self.search_android_market(term.gsub(/-/,' '))
    when 'iphone'
      self.search_apple_app_store(term, country)
    when 'windows'
      self.search_windows_marketplace(term)
    end
  end

  def self.recalculate_app_price(platform, price_in_dollars, currency)
    if currency == 'USD' || price_in_dollars == 0
      price_in_dollars
    elsif platform == 'iphone' && PRICE_TIERS[currency].present?
      PRICE_TIERS[currency].each_with_index do |tier_price, tier|
        if price_in_dollars <= tier_price
          return tier + 0.99
        end
      end

      5.99 # the price is too damn high
    else
      # TODO: Real multi-currency handling for android. For now simply set the price to a positive value if it's not USD.
      0.99
    end
  end

private

  def self.fetch_app_by_id_for_apple(id, country)
    return nil if id.blank?
    country = 'us' if country.blank?
    response = request(ITUNES_APP_URL, {:id => id, :country => country.to_s[0..1]})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      json = JSON.load(response.body)
      return json['resultCount'] > 0 ? app_info_from_apple(json['results'].first) : nil
    else
      raise "Invalid response from app store."
    end
  end

  def self.fetch_app_by_id_for_android(id)
    response = request(ANDROID_APP_URL + CGI::escape(id))
    if response.status == 200
      doc         = Hpricot(response.body)
      title       = (doc/".doc-banner-title-container"/".doc-banner-title").inner_html
      description = (doc/".doc-description"/"#doc-original-text").inner_html
      icon_url    = (doc/".doc-banner-icon"/"img").attr("src")
      publisher   = (doc/".doc-banner-title-container"/"a.doc-header-link").inner_html

      metadata = doc/".doc-metadata"
      keys = (metadata/:dt).map do |dt|
        dt.inner_html.underscore.gsub(':', '').gsub(' ', '_')
      end
      values = (metadata/:dd).map(&:inner_html)
      data_hash = Hash[keys.zip(values)]

      price       = (data_hash['price'][/\$\d\.\d\d/] || '$0').gsub('$', '').to_f
      user_rating = data_hash['rating'][/[^ ]* stars/].gsub(' stars','').to_f
      category    = (Hpricot(data_hash['category'])/:a).attr('href').split('/').last.split('?').first
      released_at = Date.parse(data_hash['updated']).strftime('%FT00:00:00Z')

      file_size   = data_hash['size'].to_f
      file_size   *= (1 << 10) if data_hash['size'][/k/i]
      file_size   *= (1 << 20) if data_hash['size'][/m/i]
      file_size   *= (1 << 30) if data_hash['size'][/g/i]

      {
        :item_id          => id,
        :title            => CGI::unescapeHTML(title),
        :description      => CGI::unescapeHTML(description),
        :icon_url         => icon_url,
        :publisher        => CGI::unescapeHTML(publisher),
        :price            => price,
        :file_size_bytes  => file_size.to_i,
        :released_at      => released_at,
        :user_rating      => user_rating,
        :categories       => [category],
      }
    else
      raise "Invalid response."
    end
  end

  def self.fetch_app_by_id_for_windows(id)
    response = request(WINDOWS_APP_URL.sub('_APPID_', CGI::escape(id)))
    if response.status == 200
      doc         = Hpricot(response.body)
      title       = (doc/:sorttitle).inner_text.strip
      description = (doc/'a:feed'/'a:content').inner_text.strip
      icon_id     = (doc/'image'/'id').inner_text.split(':').last
      icon_url    = "http://catalog.zune.net/v3.2/image/#{icon_id}?width=160&height=120"
      publisher   = (doc/'a:feed'/:publisher).inner_text.strip

      offers      = (doc/'a:feed'/:offers/:offer)
      if offers.length == 0
        price = 0
      elsif offers.length == 1
        price = (offers/:price).inner_text
      else
        offers.each do |offer|
          license = (offer/:licenseright).inner_text
          if license == 'Purchase'
            price = (offer/:price).inner_text
          end
        end
      end

      user_rating = (doc/:averageuserrating).inner_text.to_f / 2
      categories  = (doc/:categories/:category/:title).map(&:inner_text)
      released_at = Date.parse((doc/'a:feed'/:releasedate).inner_text).strftime('%FT00:00:00Z')
      file_size   = (doc/'a:entry'/:installsize).inner_text

      {
        :item_id          => id,
        :title            => CGI::unescapeHTML(title),
        :description      => CGI::unescapeHTML(description),
        :icon_url         => icon_url,
        :publisher        => CGI::unescapeHTML(publisher),
        :price            => price,
        :file_size_bytes  => file_size.to_i,
        :released_at      => released_at,
        :user_rating      => '%.2f' % user_rating,
        :categories       => categories,
      }
    else
      raise "Invalid response."
    end
  end

  def self.search_apple_app_store(term, country)
    response = request(ITUNES_SEARCH_URL, {:media => 'software', :term => term, :country => country})
    response_ipad = request(ITUNES_SEARCH_URL, {:media => 'software', :entity => 'iPadSoftware', :term => term, :country => country})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      results_iphone = JSON.load(response.body)['results']
      results_ipad = JSON.load(response_ipad.body)['results']
      return results_iphone.concat(results_ipad).map { |result| app_info_from_apple(result) }
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_apple_app_store failed for term: #{term}, country: #{country}")
      raise "Invalid response from app store."
    end
  end

  def self.search_android_market(term)
    response = request(ANDROID_SEARCH_URL + CGI::escape(term))
    if response.status == 200
      items = Hpricot(response.body)/"div.results-section.apps"/"li.goog-inline-block"
      return items.map do |item|
        icon_link   = (item/"div"/"div.thumbnail-wrapper"/"a")
        icon_url    = (icon_link/"img").attr('src')
        query_str   = URI::split(icon_link.attr('href'))[7]
        item_id     = query_str.split('&').select { |param| param =~ /id=/ }.first.split('=')[1]
        details     = item/"div"/"div.details"
        price       = (item/:div/:div/:div/'a.buy-button').attr('data-docPrice').gsub(/[^\d\.\-]/,'').to_f
        title       = (details/"a.title").inner_html
        publisher   = (details/'.goog-inline-block'/:a).inner_text
        description = ""
        {
          :item_id      => item_id,
          :title        => title,
          :icon_url     => icon_url,
          :price        => "%.2f" % price,
          :description  => description,
          :publisher    => publisher,
        }
      end
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_android_market failed for term: #{term}")
      raise "Invalid response."
    end
  end

  def self.search_windows_marketplace(term)
    response = request(WINDOWS_SEARCH_URL + CGI::escape(term.strip.gsub(/\s/, '+')))
    if response.status == 200
      items = (Hpricot(response.body)/'a:entry'/'a:id').first(10).map do |id|
        fetch_app_by_id_for_windows(id.inner_text.split(':').last)
      end
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_windows_marketplace failed for term: #{term}")
      raise "Invalid response."
    end
  end

  def self.request(url, params={})
    unless params.empty?
      url += "?" + params.map { |k, v| [ k, CGI::escape(v) ].join('=') }.join('&')
    end
    Downloader.get(url, :return_response => true, :timeout => 30)
  end

  def self.app_info_from_apple(hash)
    price_in_dollars = recalculate_app_price('iphone', hash['price'], hash['currency'])
    app_info = {
      :item_id            => hash["trackId"],
      :title              => hash["trackName"],
      :url                => hash["trackViewUrl"],
      :icon_url           => hash["artworkUrl100"],
      :small_icon_url     => hash["artworkUrl60"],
      :price              => '%.2f' % price_in_dollars,
      :description        => hash["description"],
      :publisher          => hash["artistName"],
      :file_size_bytes    => hash["fileSizeBytes"],
      :supported_devices  => hash["supportedDevices"].sort,
      :user_rating        => hash["averageUserRatingForCurrentVersion"] || hash["averageUserRating"],
      :categories         => hash["genres"],
      :released_at        => hash["releaseDate"],
      # other possibly useful values:
      #   hash["currency"],
      #   hash["version"]
      #   hash["genreIds"]
    }

    case hash["contentAdvisoryRating"]
      when "17+"
        app_info[:age_rating] = 4
      when "12+"
        app_info[:age_rating] = 3
      when "9+"
        app_info[:age_rating] = 2
      else
        app_info[:age_rating] = 1
    end

    app_info
  end

end
