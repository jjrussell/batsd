class AppStore

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

  ANDROID_SEARCH_URL = 'http://tapandmar.appspot.com/search/'
  ANDROID_APP_URL = 'http://tapandmar.appspot.com/search/'
  ANDROID_ICON_URL = 'http://tapandmar.appspot.com/icon/'
  CYRKET_ICON_URL = 'http://cache.cyrket.com/p/android/'

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
    country = 'us' if country.blank?
    response = request(APP_URL, {:id => id, :country => country.to_s[0..1]})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      json = JSON.load(response.body)
      return json['resultCount'] > 0 ? app_info_from_apple(json['results'].first) : nil
    else
      raise "Invalid response from app store."
    end
  end

  def self.fetch_app_by_id_for_android(id)
    self.search_android_marketplace(id, false).first
  end

  def self.search_apple_app_store(term, country)
    response = request(SEARCH_URL, {:media => 'software', :term => term, :country => country})
    response_ipad = request(SEARCH_URL, {:media => 'software', :entity => 'iPadSoftware', :term => term})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      results_iphone = JSON.load(response.body)['results']
      results_ipad = JSON.load(response_ipad.body)['results']
      return results_iphone.concat(results_ipad).map { |result| app_info_from_apple(result) }
    else
      raise "Invalid response from app store."
    end
  end

  def self.search_android_marketplace(term, cyrket_icon=true)
    response = request(ANDROID_SEARCH_URL + CGI::escape(term.gsub(/\s/, '+').downcase))
    if response.status == 200
      items = JSON.load(response.body)
      return items['app'].map do |hash|
        if cyrket_icon
          icon_url = CYRKET_ICON_URL + hash['packageName'] + '/icon'
        else
          icon_url = ANDROID_ICON_URL + hash['packageName']
        end
        price = hash['price'].nil? ? 0 : hash['price'].gsub(/[^\d\.\-]/,'').to_f
        {
          :item_id      => hash['packageName'],
          :title        => hash['title'],
          :icon_url     => icon_url,
          :price        => "%.2f" % price,
          :description  => hash['ExtendedInfo']['description'],
          :publisher    => hash['creator']
        }
      end
    else
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
      :item_id        => hash["trackId"],
      :title          => hash["trackName"],
      :url            => hash["trackViewUrl"],
      :icon_url       => hash["artworkUrl60"],
      :large_icon_url => hash["artworkUrl100"],
      :price          => hash["price"],
      :description    => hash["description"],
      :release_date   => hash["releaseDate"],
      :publisher      => hash["artistName"],
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
