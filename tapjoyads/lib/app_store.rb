class AppStore

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

  # returns hash of app info
  def self.fetch_app_by_id(id)
    response = request(APP_URL, :id => id)
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      json = JSON.load(response.body)
      if json['resultCount'] > 0
        return app_info(json['results'].first)
      end
    end
    return nil
  end

  # returns an array of first 24 App instances matching "term"
  def self.search(term)
    response = request(SEARCH_URL, {:media => 'software', :term => term})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      json = JSON.load(response.body)
      return json['results'].map { |result| app_info(result) }
    end
    return nil
  end

private

  def self.request(url, params={})
    unless params.empty?
      url += "?" + params.map { |k, v| [ k, CGI::escape(v) ].join('=') }.join('&')
    end
    Downloader.get(url, :return_response => true, :timeout => 30)
  end

  def self.app_info(hash)
    app_info = {
      :item_id        => hash["trackId"],
      :title          => hash["trackName"],
      :url            => hash["trackViewUrl"],
      :icon_url       => hash["artworkUrl60"],
      :large_icon_url => hash["artworkUrl100"],
      :price          => hash["price"],
      :release_date   => hash["releaseDate"],
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
