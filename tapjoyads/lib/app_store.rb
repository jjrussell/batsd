class AppStore

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

  ANDROID_APP_URL = 'https://market.android.com/details?id='
  ANDROID_SEARCH_URL = 'https://market.android.com/search?num=40&q='

  # returns hash of app info
  def self.fetch_app_by_id(id, platform='iphone', country='')
    if platform == 'android'
      return self.fetch_app_by_id_for_android(id)
    else
      return self.fetch_app_by_id_for_apple(id, country)
    end
  end

  # returns an array of first 24 App instances matching "term"
  def self.search(term, platform='iphone', country='')
    if /android/i =~ platform
      return self.search_android_marketplace(term.gsub(/-/,' '))
    else
      return self.search_apple_app_store(term.gsub(/\s/, '+'), country)
    end
  end

private

  def self.fetch_app_by_id_for_apple(id, country)
    return nil if id.blank?
    country = 'us' if country.blank?
    response = request(APP_URL, {:id => id, :country => country.to_s[0..1]})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      json = JSON.load(response.body)
      return json['resultCount'] > 0 ? app_info_from_apple(json['results'].first) : nil
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "fetch_app_by_id_for_apple failed for id: #{id}, country: #{country}")
      raise "Invalid response from app store."
    end
  end

  def self.fetch_app_by_id_for_android(id)
    response = request(ANDROID_APP_URL + CGI::escape(id))
    if response.status == 200
      doc         = Hpricot(response.body)
      title       = (doc/".doc-banner-title-container"/".doc-banner-title"/"span.fn").inner_html
      description = (doc/".doc-description"/"#doc-original-text").inner_html
      icon_url    = (doc/".doc-banner-icon"/"img").attr("src")
      publisher   = (doc/".doc-banner-title-container"/"a.doc-header-link").inner_html

      metadata = doc/".doc-metadata"/".doc-metadata-list"
      keys = (metadata/:dt).map do |dt|
        dt.inner_html.underscore.gsub(':', '').gsub(' ', '_')
      end
      values = (metadata/:dd).map(&:inner_html)
      data_hash = Hash[keys.zip(values)]

      price       = (data_hash['price'][/\$\d\.\d\d/] || '$0').gsub('$', '').to_f
      user_rating = data_hash['rating'][/[^ ]* stars/].gsub(' stars','').to_f
      category    = (Hpricot(data_hash['category'])/:a).attr('href').split('/').last
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
      Notifier.alert_new_relic(AppStoreSearchFailed, "fetch_app_by_id_for_android failed for id: #{id}")
      raise "Invalid response."
    end
  end

  def self.search_apple_app_store(term, country)
    response = request(SEARCH_URL, {:media => 'software', :term => term, :country => country})
    response_ipad = request(SEARCH_URL, {:media => 'software', :entity => 'iPadSoftware', :term => term, :country => country})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      results_iphone = JSON.load(response.body)['results']
      results_ipad = JSON.load(response_ipad.body)['results']
      return results_iphone.concat(results_ipad).map { |result| app_info_from_apple(result) }
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_apple_app_store failed for term: #{term}, country: #{country}")
      raise "Invalid response from app store."
    end
  end

  def self.search_android_marketplace(term)
    response = request(ANDROID_SEARCH_URL + CGI::escape(term.strip.gsub(/\s/, '+')))
    if response.status == 200
      items = Hpricot(response.body)/"ul.search-results-list"/"li.search-results-item"
      return items.map do |item|
        icon_link   = (item/"div"/"div.thumbnail-wrapper"/"a")
        icon_url    = (icon_link/"img").attr('src')
        query_str   = URI::split(icon_link.attr('href'))[7]
        item_id     = query_str.split('&').select { |param| param =~ /id=/ }.first.split('=')[1]
        details     = item/"div"/"div.details"
        price_span  = details/"div.buy-wrapper"/"div"/"a"/"span"
        price       = price_span.inner_html.gsub(/[^\d\.\-]/,'').to_f
        title       = (details/"a.title").inner_html
        publisher   = (details/"p"/"span.attribution"/"a").inner_html
        description = (details/"p.snippet-content").inner_html
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
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_android_marketplace failed for term: #{term}")
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
    app_info = {
      :item_id            => hash["trackId"],
      :title              => hash["trackName"],
      :url                => hash["trackViewUrl"],
      :icon_url           => hash["artworkUrl100"],
      :small_icon_url     => hash["artworkUrl60"],
      :price              => hash["price"],
      :description        => hash["description"],
      :publisher          => hash["artistName"],
      :file_size_bytes    => hash["fileSizeBytes"],
      :supported_devices  => hash["supportedDevices"].sort,
      :user_rating        => hash["averageUserRatingForCurrentVersion"] || hash["averageUserRating"],
      :categories         => hash["genres"],
      :released_at        => hash["releaseDate"],
      :currency           => hash["currency"],
      # other possibly useful values:
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
