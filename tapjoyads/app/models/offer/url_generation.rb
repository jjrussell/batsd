module Offer::UrlGeneration

  def destination_url(options)
    if instructions.present?
      instructions_url(options)
    else
      complete_action_url(options)
    end
  end

  def instructions_url(options)
    udid                  = options.delete(:udid)                  { |k| raise "#{k} is a required argument" }
    publisher_app_id      = options.delete(:publisher_app_id)      { |k| raise "#{k} is a required argument" }
    currency              = options.delete(:currency)              { |k| raise "#{k} is a required argument" }
    click_key             = options.delete(:click_key)             { nil }
    language_code         = options.delete(:language_code)         { nil }
    itunes_link_affiliate = options.delete(:itunes_link_affiliate) { nil }
    display_multiplier    = options.delete(:display_multiplier)    { 1 }
    library_version       = options.delete(:library_version)       { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    data = {
      :id                    => id,
      :udid                  => udid,
      :publisher_app_id      => publisher_app_id,
      :click_key             => click_key,
      :itunes_link_affiliate => itunes_link_affiliate,
      :currency_id           => currency.id,
      :language_code         => language_code,
      :display_multiplier    => display_multiplier,
      :library_version       => library_version,
    }

    "#{API_URL}/offer_instructions?data=#{ObjectEncryptor.encrypt(data)}"
  end

  def complete_action_url(options)
    udid                  = options.delete(:udid)                  { |k| raise "#{k} is a required argument" }
    publisher_app_id      = options.delete(:publisher_app_id)      { |k| raise "#{k} is a required argument" }
    currency              = options.delete(:currency)              { |k| raise "#{k} is a required argument" }
    click_key             = options.delete(:click_key)             { nil }
    itunes_link_affiliate = options.delete(:itunes_link_affiliate) { nil }
    library_version       = options.delete(:library_version)       { nil }
    options.delete(:language_code)
    options.delete(:display_multiplier)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    final_url = url.gsub('TAPJOY_UDID', udid.to_s)
    if item_type == 'App'
      final_url = Linkshare.add_params(final_url, itunes_link_affiliate)
      if library_version.nil? || library_version.version_greater_than_or_equal_to?('8.1.1')
        final_url.sub!('market://search?q=', 'http://market.android.com/details?id=')
      end
    elsif item_type == 'EmailOffer'
      final_url += "&publisher_app_id=#{publisher_app_id}"
    elsif item_type == 'GenericOffer'
      advertiser_app_id = click_key.to_s.split('.')[1]
      final_url.gsub!('TAPJOY_GENERIC_INVITE', advertiser_app_id) if advertiser_app_id
      final_url.gsub!('TAPJOY_GENERIC', click_key.to_s)
      if has_variable_payment?
        extra_params = {
          :uid      => Digest::SHA256.hexdigest(udid + UDID_SALT),
          :cvr      => currency.spend_share * currency.conversion_rate / 100,
          :currency => CGI::escape(currency.name),
        }
        mark = '?'
        mark = '&' if final_url =~ /\?/
        final_url += "#{mark}#{extra_params.to_query}"
      end
    elsif item_type == 'ActionOffer'
      final_url = url
    elsif item_type == 'SurveyOffer'
      final_url.gsub!('TAPJOY_SURVEY', click_key.to_s)
      final_url = ObjectEncryptor.encrypt_url(final_url)
    end

    final_url
  end

  def click_url(options)
    publisher_app      = options.delete(:publisher_app)      { |k| raise "#{k} is a required argument" }
    publisher_user_id  = options.delete(:publisher_user_id)  { |k| raise "#{k} is a required argument" }
    udid               = options.delete(:udid)               { |k| raise "#{k} is a required argument" }
    currency_id        = options.delete(:currency_id)        { |k| raise "#{k} is a required argument" }
    source             = options.delete(:source)             { |k| raise "#{k} is a required argument" }
    app_version        = options.delete(:app_version)        { nil }
    viewed_at          = options.delete(:viewed_at)          { |k| raise "#{k} is a required argument" }
    displayer_app_id   = options.delete(:displayer_app_id)   { nil }
    exp                = options.delete(:exp)                { nil }
    primary_country    = options.delete(:primary_country)    { nil }
    language_code      = options.delete(:language_code)      { nil }
    display_multiplier = options.delete(:display_multiplier) { 1 }
    device_name        = options.delete(:device_name)        { nil }
    library_version    = options.delete(:library_version)    { nil }
    gamer_id           = options.delete(:gamer_id)           { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    click_url = "#{API_URL}/click/"
    if item_type == 'App' || item_type == 'EmailOffer'
      click_url += "app"
    elsif item_type == 'GenericOffer'
      click_url += "generic"
    elsif item_type == 'RatingOffer'
      click_url += "rating"
    elsif item_type == 'TestOffer'
      click_url += "test_offer"
    elsif item_type == 'TestVideoOffer'
      click_url += "test_video_offer"
    elsif item_type == 'ActionOffer'
      click_url += "action"
    elsif item_type == 'VideoOffer'
      click_url += "video"
    elsif item_type == 'SurveyOffer'
      click_url += "survey"
    else
      raise "click_url requested for an offer that should not be enabled. offer_id: #{id}"
    end

    data = {
      :advertiser_app_id  => item_id,
      :publisher_app_id   => publisher_app.id,
      :publisher_user_id  => publisher_user_id,
      :udid               => udid,
      :source             => source,
      :offer_id           => id,
      :app_version        => app_version,
      :viewed_at          => viewed_at.to_f,
      :currency_id        => currency_id,
      :primary_country    => primary_country,
      :displayer_app_id   => displayer_app_id,
      :exp                => exp,
      :language_code      => language_code,
      :display_multiplier => display_multiplier,
      :device_name        => device_name,
      :library_version    => library_version,
      :gamer_id           => gamer_id
    }

    "#{click_url}?data=#{ObjectEncryptor.encrypt(data)}"
  end

  def display_ad_image_url(publisher_app_id, width, height, currency_id = nil, display_multiplier = nil, bust_cache = false, use_cloudfront = true, preview = false)
    size = "#{width}x#{height}"

    delim = '?'
    if display_custom_banner_for_size?(size) || (preview && has_banner_creative?(size))
      url = "#{use_cloudfront ? CLOUDFRONT_URL : "https://s3.amazonaws.com/#{BucketNames::TAPJOY}"}/#{banner_creative_path(size)}"
    else
      display_multiplier = (display_multiplier || 1).to_f
      url = "#{API_URL}/display_ad/image?publisher_app_id=#{publisher_app_id}&advertiser_app_id=#{id}&size=#{size}&display_multiplier=#{display_multiplier}&currency_id=#{currency_id}&offer_type=#{item_type}"
      delim = '&'
    end
    url << "#{delim}ts=#{Time.now.to_i}" if bust_cache
    url
  end

  def preview_display_ad_image_url(publisher_app_id, width, height)
    display_ad_image_url(publisher_app_id, width, height, nil, nil, true, false, true)
  end

  def fullscreen_ad_image_url(publisher_app_id, bust_cache = false, dimensions = nil)
    if dimensions.present? && display_custom_banner_for_size?(dimensions)
      url = "#{CLOUDFRONT_URL}/#{banner_creative_path(size)}"
    else
      url = "#{API_URL}/fullscreen_ad/image?publisher_app_id=#{publisher_app_id}&offer_id=#{id}"
    end
    url << "&ts=#{Time.now.to_i}" if bust_cache
    options.each do |key,value|
      url << "&#{key}=#{value}"
    end
    url
  end

  def fullscreen_ad_url(options)
    publisher_app_id   = options.delete(:publisher_app_id)   { |k| raise "#{k} is a required argument" }
    publisher_user_id  = options.delete(:publisher_user_id)  { |k| }
    udid               = options.delete(:udid)               { |k| }
    currency_id        = options.delete(:currency_id)        { |k| }
    source             = options.delete(:source)             { |k| }
    app_version        = options.delete(:app_version)        { nil }
    viewed_at          = options.delete(:viewed_at)          { |k| }
    displayer_app_id   = options.delete(:displayer_app_id)   { nil }
    exp                = options.delete(:exp)                { nil }
    primary_country    = options.delete(:primary_country)    { nil }
    display_multiplier = options.delete(:display_multiplier) { 1 }
    library_version    = options.delete(:library_version)    { nil }
    language_code      = options.delete(:language_code)      { nil }

    # Allow screen size to be specified for ad previews
    width              = options.delete(:width)              { nil }
    height             = options.delete(:height)             { nil }
    preview            = options.delete(:preview)            { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    ad_url = "#{API_URL}/fullscreen_ad"
    ad_url << "/test_offer" if item_type == 'TestOffer'
    ad_url << "/test_video_offer" if item_type == 'TestVideoOffer'

    ad_url << "?advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app_id}&publisher_user_id=#{publisher_user_id}" <<
      "&udid=#{udid}&source=#{source}&offer_id=#{id}&app_version=#{app_version}&viewed_at=#{viewed_at.to_f}" <<
      "&currency_id=#{currency_id}&primary_country=#{primary_country}&display_multiplier=#{display_multiplier}" <<
      "&library_version=#{library_version}&language_code=#{language_code}"
    ad_url << "&displayer_app_id=#{displayer_app_id}" if displayer_app_id.present?
    ad_url << "&exp=#{exp}" if exp.present?
    ad_url << "&width=#{width}" if width.present?
    ad_url << "&height=#{height}" if height.present?
    ad_url << "&preview=#{preview}" if preview.present?
    ad_url
  end

  def get_offers_webpage_preview_url(publisher_app_id, bust_cache = false)
    url = "#{API_URL}/get_offers/webpage?app_id=#{publisher_app_id}&offer_id=#{id}"
    url << "&ts=#{Time.now.to_i}" if bust_cache
    url
  end
end
