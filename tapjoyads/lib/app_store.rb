class AppStore
  attr_accessor :id, :name, :platform, :store_url, :info_url, :sdk_name

  ANDROID_APP_URL      = 'https://play.google.com/store/apps/details?id='
  ANDROID_SEARCH_URL   = 'https://play.google.com/store/search?c=apps&q='
  ITUNES_APP_URL       = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup'
  ITUNES_SEARCH_URL    = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsSearch'
  WINDOWS_APP_URL      = 'http://catalog.zune.net/v3.2/en-US/apps/_APPID_?store=Zest&clientType=WinMobile+7.0'
  WINDOWS_SEARCH_URL   = 'http://catalog.zune.net/v3.2/_ACCEPT_LANGUAGE_/?includeApplications=true&prefix='
  WINDOWS_APP_IMAGES   = 'http://catalog.zune.net/v3.2/en-US/image/_IMGID_?width=1280&amp;height=720&amp;resize=true'
  GFAN_APP_URL         = 'http://api.gfan.com/market/api/getProductDetail'
  GFAN_SEARCH_URL      = 'http://api.gfan.com/market/api/search'
  SKT_STORE_SPID       = 'OASP_tapjoy'
  SKT_BASEURL          = '220.103.229.113:8600'
  SKT_STORE_APP_URL    = "http://#{SKT_BASEURL}/api/openapi/getAppInfo.omp?cmd=getAppInfo"
  SKT_STORE_SEARCH_URL = "http://#{SKT_BASEURL}/api/openapi/tstore.omp?cmd=getSearchProductByName&ua_code=SSMF&mdn=01012341234&category_type=DP0005&display_count=10&current_page=1&order=D"

  SKT_STORE_CURRENCY   = 'KRW'

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

  def initialize(options = {})
    @id        = options.delete(:id)
    @name      = options.delete(:name)
    @platform  = options.delete(:platform)
    @store_url = options.delete(:store_url)
    @info_url  = options.delete(:info_url)
    @exclusive = options.delete(:exclusive)
    @sdk_name  = options.delete(:sdk_name)

    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
  end

  def exclusive?
    !!@exclusive
  end

  SUPPORTED_STORES = {
    'iphone.AppStore' => AppStore.new({
      :id        => 'iphone.AppStore',
      :name      => 'App Store',
      :platform  => 'iphone',
      :store_url => 'http://itunes.apple.com/app//idSTORE_ID?mt=8',
      :info_url  => 'http://itunes.apple.com/app//idSTORE_ID?mt=8',
    }),
    'android.GooglePlay' => AppStore.new({
      :id        => 'android.GooglePlay',
      :name      => 'Google Play',
      :platform  => 'android',
      :store_url => 'market://search?q=STORE_ID',
      :info_url  => 'https://play.google.com/store/apps/details?id=STORE_ID',
      :exclusive => true,
      :sdk_name  => 'google'
    }),
    'android.GFan' => AppStore.new({
      :id        => 'android.GFan',
      :name      => 'GFan (China)',
      :platform  => 'android',
      :store_url => 'http://3g.gfan.com/data/index.php?/detail/index/STORE_ID',
      :info_url  => 'http://3g.gfan.com/data/index.php?/detail/index/STORE_ID',
      :exclusive => true,
      :sdk_name  => 'gfan'
    }),
    'android.SKTStore' => AppStore.new({
      :id        => 'android.SKTStore',
      :name      => 'T-Store (Korea)',
      :platform  => 'android',
      :store_url => 'http://m.tstore.co.kr/userpoc/mp.jsp?pid=STORE_ID',
      :info_url  => 'http://m.tstore.co.kr/userpoc/mp.jsp?pid=STORE_ID',
      :exclusive => true,
      :sdk_name  => 'skt'
    }),
    'windows.Marketplace' => AppStore.new({
      :id        => 'windows.Marketplace',
      :name      => 'Marketplace',
      :platform  => 'windows',
      :store_url => 'http://social.zune.net/redirect?type=phoneapp&id=STORE_ID',
      :info_url  => 'http://windowsphone.com/s?appId=STORE_ID'
    }),
  }

  SDK_STORE_NAMES = {
    'google' => 'android.GooglePlay',
    'gfan'   => 'android.GFan',
    'skt'    => 'android.SKTStore',
  }

  def self.find(id)
    SUPPORTED_STORES[id]
  end

  def self.android_store_options
    store_options = {}
    SUPPORTED_STORES.each do |key, store|
      store_options[store.name] = store.id if store.platform == 'android'
    end
    store_options
  end

  # returns hash of app info
  def self.fetch_app_by_id(id, platform, store_name, country='')
    case platform.downcase
    when 'android'
      if store_name == 'android.GFan'
        self.fetch_app_by_id_for_gfan(id)
      elsif store_name == 'android.SKTStore'
        self.fetch_app_by_id_for_skt_store(id)
      else
        self.fetch_app_by_id_for_android(id)
      end
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
      nil # not supported
    end
  end

  # returns an array of first 24 App instances matching "term"
  def self.search(term, platform, store_name, country='')
    term = term.strip.gsub(/\s/, '+')
    case platform.downcase
    when 'android'
      if store_name == 'android.GFan'
        self.search_gfan_app_store(term)
      elsif store_name == 'android.SKTStore'
        self.search_skt_store(term)
      else
        self.search_android_market(term.gsub(/-/,' '))
      end
    when 'iphone'
      self.search_apple_app_store(term, country)
    when 'windows'
      self.search_windows_marketplace(term, country)
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
      screenshot_urls = []
      (doc/".screenshot-carousel-content-container"/"img").each do |img|
        screenshot_urls << img.attributes['data-baseUrl']
      end

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
        :screenshot_urls  => screenshot_urls,
        :publisher        => CGI::unescapeHTML(publisher),
        :price            => price,
        :file_size_bytes  => file_size.to_i,
        :released_at      => released_at,
        :user_rating      => user_rating,
        :categories       => [category],
      }
    else
      raise RuntimeError, "Invalid response."
    end
  end

  def self.fetch_app_by_id_for_windows(id)
    response = request(WINDOWS_APP_URL.sub('_APPID_', CGI::escape(id)))
    if response.status == 200
      doc               = Hpricot(response.body)
      title             = (doc/:sorttitle).inner_text.strip
      description       = (doc/'a:feed'/'a:content').inner_text.strip
      icon_id           = (doc/'image'/'id').inner_text.split(':').last
      icon_url          = "http://catalog.zune.net/v3.2/image/#{icon_id}?width=160&height=120"
      publisher         = (doc/'a:feed'/:publisher).inner_text.strip
      screenshot_urls   = []

      (doc/'screenshots'/'screenshot').each do |screenshot|
        screenshot_urls << WINDOWS_APP_IMAGES.sub('_IMGID_', screenshot.inner_text.split(':').last)
      end

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
        :screenshot_urls  => screenshot_urls,
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

  def self.fetch_app_by_id_for_gfan(id)
    data = "<request><p_id>#{id}</p_id><source_type>0</source_type></request>" #Base64 TEA and mappn key pending from Song Peng
    response = request(GFAN_APP_URL, {}, data)

    if response.status == 200
      doc = XML::Parser.string(response.body).parse
      product = doc.find('//product').first
      {
        :item_id          => id,
        :title            => CGI::unescapeHTML(product['name']),
        :description      => CGI::unescapeHTML(product['long_description']),
        :icon_url         => product['icon_url'],
        :screenshot_urls  => [1, 2, 3, 4, 5].collect{ |i| product["screenshot_#{i}"] }.reject{ |x| x.blank? },
        :publisher        => CGI::unescapeHTML(product['author_name']),
        :price            => product['price'].to_f,
        :file_size_bytes  => product['app_size'].to_i,
        :released_at      => Time.at(product['publish_time'][0...10].to_i).strftime('%FT00:00:00Z'),
        :user_rating      => (product['rating'].to_i / 10.0).to_f,
        :categories       => [product['product_type']],
      }
    else
      raise "Invalid response."
    end
  end

  def self.fetch_app_by_id_for_skt_store(id)
    response = request(SKT_STORE_APP_URL + "&sp_id=#{SKT_STORE_SPID}&pid=#{CGI::escape(id)}")
    if response.status == 200
      doc = XML::Parser.string(response.body).parse
      result = doc.find('//Result').first
      {
        :item_id          => id,
        :title            => CGI::unescapeHTML(result.find('//name').first.content),
        :description      => CGI::unescapeHTML(result.find('//prod_dtl_desc').first.content),
        :icon_url         => result.find('//icon').first.content,
        :publisher        => CGI::unescapeHTML(result.find('//dev_name').first.content),
        :price            => CurrencyExchange.convert_foreign_to_usd(result.find('//charge').first.content.to_f, SKT_STORE_CURRENCY),
        :user_rating      => result.find('//rate').first.content.to_f,
        :categories       => [result.find('//category').first.content],
      }
    else
      raise "Invalid response."
    end
  end

  def self.search_apple_app_store(term, country)
    country = 'us' if country.blank?
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
      items = Hpricot(response.body)/"ul.search-results-list"/"li.search-results-item"
      items = Hpricot(response.body)/"div.container-contents.apps"/"ul"/"li" if items.blank?
      return items.map do |item|
        icon_link   = (item/"div"/"div.thumbnail-wrapper"/"a")
        icon_url    = (icon_link/"img").attr('src')
        query_str   = URI::split(icon_link.attr('href'))[7]
        item_id     = query_str.split('&').select { |param| param =~ /id=/ }.first.split('=')[1]
        details     = item/"div"/"div.details"
        price       = (item/'.buy-offer').attr('data-docPrice').gsub(/[^\d\.\-]/,'').to_f
        title       = (details/"a.title").inner_html
        publisher   = (details/'.goog-inline-block'/:a).first.inner_text
        {
          :item_id      => item_id,
          :title        => title,
          :icon_url     => icon_url,
          :price        => "%.2f" % price,
          :description  => '',
          :publisher    => publisher,
        }
      end
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_android_market failed for term: #{term}")
      raise "Invalid response."
    end
  end

  def self.search_windows_marketplace(term, accept_language)
    unless App::WINDOWS_ACCEPT_LANGUAGES.include?(accept_language)
      accept_language = 'en-us'
    end
    url = WINDOWS_SEARCH_URL.gsub('_ACCEPT_LANGUAGE_', accept_language)
    response = request(url + CGI::escape(term.strip.gsub(/\s/, '+')))
    if response.status == 200
      items = (Hpricot(response.body)/'a:entry'/'a:id').first(10).map do |id|
        store_id = id.inner_text.split(':').last
        next if store_id == '/'
        fetch_app_by_id_for_windows(store_id)
      end.compact
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_windows_marketplace failed for term: #{term}")
      raise "Invalid response."
    end
  end

  def self.search_gfan_app_store(term)
    list_size = 10
    data = "<request><size>#{list_size}</size>" +
      '<start_position>0</start_position>' +
      '<platform>8</platform>' +
      '<screen_size>240#320</screen_size>' +
      "<keyword>#{term}</keyword>" +
      '<match_type>1</match_type></request>' #Base64 TEA and mappn key pending from Song Peng
    response = request(GFAN_SEARCH_URL, {}, data)

    if response.status == 200
      doc = XML::Parser.string(response.body).parse
      return doc.find('//product').map do |product|
        {
          :item_id          => product['p_id'],
          :title            => CGI::unescapeHTML(product['name']),
          :description      => CGI::unescapeHTML(product['short_description']),
          :icon_url         => product['icon_url'],
          :publisher        => CGI::unescapeHTML(product['author_name']),
          :price            => product['price'].to_f,
          :file_size_bytes  => product['app_size'].to_i,
          :user_rating      => (product['rating'].to_i / 10.0).to_f,
          :categories       => [product['product_type']],
        }
      end
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_gfan_store failed for term: #{term}")
      raise "Invalid response."
    end
  end

  def self.search_skt_store(term)
    response = request(SKT_STORE_SEARCH_URL + "&sp_id=#{SKT_STORE_SPID}&keyword=#{term}")
    if response.status == 200
      doc = XML::Parser.string(response.body).parse
      return doc.find('//ITEM').map do |item|
        {
          :item_id          => item.find('//product_id').first.content,
          :title            => CGI::unescapeHTML(item.find('//title').first.content),
          :description      => CGI::unescapeHTML(item.find('//description').first.content),
          :icon_url         => item.find('image_url').first.content,
          :price            => CurrencyExchange.convert_foreign_to_usd(item.find('//price').first.content.to_f, SKT_STORE_CURRENCY),
          :user_rating      => item.find('//rate').first.content.to_f,
        }
      end
    else
      Notifier.alert_new_relic(AppStoreSearchFailed, "search_tstore failed for term: #{term}")
      raise "Invalid response."
    end
  end

  def self.request(url, params={}, data=nil)
    unless params.empty?
      url += "?" + params.map { |k, v| [ k, CGI::escape(v) ].join('=') }.join('&')
    end
    options = { :return_response => true, :timeout => 30 }
    if data.present?
      Downloader.post(url, data, options)
    else
      Downloader.get(url, options)
    end
  end

  def self.app_info_from_apple(hash)
    price_in_dollars = recalculate_app_price('iphone', hash['price'], hash['currency'])
    app_info = {
      :item_id                => hash["trackId"],
      :title                  => hash["trackName"],
      :url                    => hash["trackViewUrl"],
      :icon_url               => hash["artworkUrl100"],
      :small_icon_url         => hash["artworkUrl60"],
      :screenshot_urls        => hash['screenshotUrls'] || hash['ipadScreenshotUrls'],
      :price                  => '%.2f' % price_in_dollars,
      :description            => hash["description"],
      :publisher              => hash["artistName"],
      :file_size_bytes        => hash["fileSizeBytes"],
      :supported_devices      => hash["supportedDevices"].sort,
      :user_rating            => hash["averageUserRatingForCurrentVersion"] || hash["averageUserRating"],
      :categories             => hash["genres"],
      :released_at            => hash["releaseDate"],
      :languages              => hash['languageCodesISO2A'].join(', ') ,
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
