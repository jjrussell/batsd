class StoreRequestError < StandardError; end

module AppStore
  extend self
  
  def app_url
    @app_url ||= 'http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware'
  end
  
  def search_url
    @search_url ||= 'http://ax.search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search'
  end
  
  
  # returns an App instance
  def fetch_app_by_id(id)
    response  = request(app_url,{:id => id})
    return nil unless response.status == 200
    return nil unless response.headers['Content-Type'] == 'text/xml'
    
    plist = Plist::parse_xml(response.body)
    return nil unless plist['item-metadata']
    app   = StoreInfoApp.new(plist["item-metadata"])
  end
  
  # returns an array of first 24 App instances matching "term"
  def search(term)
    response = request(search_url, {:media => 'software', :term => term})
    return nil unless response.status == 200
    plist = Plist::parse_xml(response.body)
    plist["items"].inject([]) { |arr,item| arr << App.new(item) unless item["type"] == "more"; arr }
  end
  
private
  
  def request(url,params={})
    
    url += "?" unless params.empty?
    
    params.each do |param|
      url += "#{param[0]}=#{CGI::escape(param[1])}"
    end
    
    Downloader.get(url, :headers => {"X-Apple-Store-Front" => '13441-1,2', "User-Agent" => 'iTunes-iPhone/3.0'}, :return_response => true)
  end
  
end

class StoreInfoApp
  
  attr_reader :item_id, :title, :url, :icon_url, :price, :release_date, :age_rating
  
  def initialize(hash)
    
    @item_id      = hash["item-id"]
    @title        = hash["title"]
    @url          = hash["url"]
    @icon_url     = hash["artwork-urls"][0]["url"]
    @price        = hash["store-offers"]["STDQ"]["price"]
    @release_date = hash["release-date"]
    str_rating    = hash["rating"]["label"]
    
    @age_rating = 1
    @age_rating = 2 if str_rating == "9+"
    @age_rating = 3 if str_rating == "12+"
    @age_rating = 4 if str_rating == "17+"
    
  end
  
end