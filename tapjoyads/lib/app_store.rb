module AppStore
  extend self

  APP_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  SEARCH_URL = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'

  # returns hash of app info
  def fetch_app_by_id(id)
    response  = request(APP_URL, :id => id)
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      app_info(JSON.load(response.body)["results"].first)
    end
  end

  # returns an array of first 24 App instances matching "term"
  def search(term)
    response = request(SEARCH_URL, {:media => 'software', :term => term})
    if (response.status == 200) && (response.headers['Content-Type'] =~ /javascript/)
      JSON.load(response.body)["results"].map do |result|
        app_info(result)
      end
    end
  end

private

  def request(url, params={})
    unless params.empty?
      url += "?" + params.map{|k,v| [k, CGI::escape(v)].join('=') }.join('&')
    end
    Downloader.get(url, :headers => {"X-Apple-Store-Front" => '13441-1,2', "User-Agent" => 'iTunes/9.2.1'}, :return_response => true)
  end

  def app_info(hash)
    app_info = {
      :item_id      => hash["trackId"],
      :title        => hash["trackName"],
      :url          => hash["trackViewUrl"],
      :icon_url     => hash["artworkUrl60"],
      :price        => hash["price"],
      :release_date => hash["releaseDate"],
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

    return app_info
  end

end
