class AppStore

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

  ANDROID_SEARCH_URL = 'http://www.appbrain.com/search'
  ANDROID_APP_URL = 'http://www.appbrain.com/app/'
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
    response = request(ANDROID_APP_URL + id)
    if response.status == 200
      doc = Hpricot.parse(response.body)
      app = (doc/"div.appPage").first
      title = (app/"div h1").text
      icon_url = (app/"div h1 img").first.attributes['src']
      publisher = (app/"div div a").first.inner_html
      price = "%.2f" % (app/"div"/"span.priceFree,span.pricePaid").first.inner_html.gsub(/\$/, '').to_f
      description = (doc/".appPage p").last.inner_html.split(/Latest version/).first
      {
        :item_id => id,
        :title => title.strip,
        :icon_url => icon_url,
        :price => price,
        :description => description.strip,
        :publisher => publisher.strip
      }
    else
      raise "Invalid response from Android App Search: #{response.status}"
    end
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

  def self.search_android_marketplace(term)
    response = request(ANDROID_SEARCH_URL, {:market => 'android', :q => term})
    if response.status == 200
      doc = Hpricot.parse(response.body)
      if (doc/"a.result").size > 0
        return (doc/"a.result").map do |link|
          {
            :item_id => link.attributes['href'].split(/\//).last,
            :title => link.attributes['title'],
            :icon_url => (link/"img.icon").first.attributes['src'],
            :price => "%.2f" % (link/"span"/"span.priceBox").text.gsub(/\$/, '').to_f,
            :description => (link/"span"/"span.appSnippet"/"span.snippet").text.strip,
            :publisher => (link/"span"/"span.appSnippet"/"span.dev").first.inner_html.sub('by ',''),
          }
        end
      else
        return [ ]
      end
    else
      raise "Invalid response from Cyrket"
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
