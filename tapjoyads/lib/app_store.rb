class AppStore

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

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
    self.search_android_marketplace(id).first
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
      :icon_url           => hash["artworkUrl60"],
      :large_icon_url     => hash["artworkUrl100"],
      :price              => hash["price"],
      :description        => hash["description"],
      :release_date       => hash["releaseDate"],
      :publisher          => hash["artistName"],
      :file_size_bytes    => hash["fileSizeBytes"],
      :supported_devices  => hash["supportedDevices"].sort
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
