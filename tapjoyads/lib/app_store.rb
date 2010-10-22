class AppStore

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

  ANDROID_SEARCH_URL = 'http://www.cyrket.com/search'
  ANDROID_APP_URL = 'http://www.cyrket.com/p/android/'

  # returns hash of app info
  def self.fetch_app_by_id(id, platform='iphone')
    if platform == 'android'
      return self.fetch_app_by_id_for_android(id)
    else
      return self.fetch_app_by_id_for_apple(id)
    end
  end

  # returns an array of first 24 App instances matching "term"
  def self.search(term, platform='iphone', country='us')
    if platform == 'android'
      return self.search_android_marketplace(term)
    else
      return self.search_apple_app_store(term, country)
    end
  end

private

  def self.fetch_app_by_id_for_apple(id)
    response = request(APP_URL, :id => id)
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
      self.app_info_from_android(doc)
    else
      raise "Invalid response from Cyrket"
    end
  end

  def self.app_info_from_android(doc)
    div = (doc/".basic.item").first
    
    icon_url = (div/".image").first.attributes['src']
    item_id = icon_url.match(/android\/(.*)\/icon/)[1]
    title = (div/".title").text
    publisher = (div/".owner").text
    description = (doc/".description").first.html
    
    price = (doc/"label").find {|a| a.html == "Price"}.following_siblings[0].html.gsub(/\s|\$/, '').to_f
    
    {
      :item_id => item_id,
      :title => title,
      :icon_url => icon_url,
      :price => price,
      :description => description,
      :publisher => publisher,
    }
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
      
      if (doc/".autopagerize_page_element .basic").size > 0
        (doc/".autopagerize_page_element .basic").map do |div|
          icon_url = (div/".icon").first.attributes['src']
          item_id = icon_url.match(/android\/(.*)\/icon/)[1]
          price = "%.2f" % (div/".price").text.gsub(/\$/, '').to_f
          {
            :item_id => item_id,
            :title => (div/".title").text,
            :icon_url => icon_url,
            :price => price,
            :description => (div/".headline").text,
            :publisher => (div/".owner").text,
          }
        end
      else
        return [ self.app_info_from_android(doc) ]
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
