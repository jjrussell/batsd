module GetOffersHelper

  def get_next_link_json
    return nil if @more_data_available < 1
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['json'] = "1"
    "/get_offers?data=#{ObjectEncryptor.encrypt(tmp_params)}"
  end

  def get_next_link_json_redesign
    return nil if @more_data_available < 1
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['json'] = "1"
    tmp_params['redesign'] = 'true'
    "/get_offers/webpage?data=#{ObjectEncryptor.encrypt(tmp_params)}"
  end

  def get_currency_link(currency)
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['currency_id'] = currency.id
    url = "/get_offers/webpage?data=#{ObjectEncryptor.encrypt(tmp_params)}"
    link_to(currency.name, url)
  end

  def get_age_gating_url(options = {})
    data = params.merge({ :options => options })
    "#{API_URL}/offer_age_gating?data=#{ObjectEncryptor.encrypt(data)}"
  end

  def get_click_url(offer, options = {})
    click_url = offer.click_url(
      :publisher_app      => @publisher_app,
      :publisher_user_id  => params[:publisher_user_id],
      :udid               => params[:udid],
      :currency_id        => @currency.id,
      :source             => options.delete(:source) { params[:source] },
      :app_version        => params[:app_version],
      :viewed_at          => @now,
      :exp                => params[:exp],
      :primary_country    => geoip_data[:primary_country],
      :language_code      => params[:language_code],
      :display_multiplier => params[:display_multiplier],
      :device_name        => params[:device_name],
      :library_version    => params[:library_version],
      :gamer_id           => params[:gamer_id],
      :os_version         => params[:os_version],
      :mac_address        => params[:mac_address],
      :device_type        => params[:device_type],
      :offerwall_rank     => options.delete(:offerwall_rank) { nil },
      :view_id            => options.delete(:view_id)        { nil },
      :date_of_birth      => options.delete(:date_of_birth)  { nil },
      :store_name         => params[:store_name]
      )

    if offer.item_type == 'VideoOffer' || offer.item_type == 'TestVideoOffer'
      if @publisher_app.platform == 'windows'
        prefix = "http://tjvideo.tjvideo.com/tjvideo?"
      else
        prefix = "tjvideo://"
      end

      video_complete_url = offer.destination_url(
        :publisher_user_id  => params[:publisher_user_id],
        :publisher_app_id   => @publisher_app.id,
        :currency           => @currency,
        :udid               => params[:udid]
      )

      parameters = "video_id=#{offer.id}&"
      parameters << "amount=#{@currency.get_visual_reward_amount(offer, params[:display_multiplier])}&"
      parameters << "currency_name=#{URI::escape(@currency.name)}&"
      parameters << "click_url=#{click_url}&"
      parameters << "video_url=#{offer.url}&"
      parameters << "video_complete_url=#{video_complete_url}"

      "#{prefix}#{parameters}"
    else
      click_url
    end
  end

  def get_fullscreen_ad_url(offer)
    offer.fullscreen_ad_url(
        :publisher_app_id   => @publisher_app.id,
        :publisher_user_id  => params[:publisher_user_id],
        :udid               => params[:udid],
        :currency_id        => @currency.id,
        :source             => params[:source],
        :app_version        => params[:app_version],
        :viewed_at          => @now,
        :exp                => params[:exp],
        :primary_country    => geoip_data[:primary_country],
        :display_multiplier => params[:display_multiplier],
        :library_version    => params[:library_version],
        :language_code      => params[:language_code],
        :os_version         => params[:os_version])
  end

  def visual_cost(offer)
    if offer.price <= 0
      t 'text.offerwall.free'
    elsif offer.price <= 100
      '$'
    elsif offer.price <= 200
      '$$'
    elsif offer.price <= 300
      '$$$'
    else
      '$$$+'
    end
  end

  def link_to_missing_currency(format = 'html')
    link_to(t('text.offerwall.missing_currency', :currency => @currency.name),
      new_support_request_path(missing_currency_support_params(format)))
  end

  def missing_currency_support_params(format = 'html')
    support_params = [ :app_id, :currency_id, :udid, :device_type, :publisher_user_id, :language_code ].inject({}) { |h,k| h[k] = params[k]; h }
    support_params[:format] = format
    support_params
  end

  def featured_offer_text(offer, currency)
    return '' unless offer.item_type == 'App'
    (offer.rewarded? && currency.rewarded?) ? t('text.featured.download_and_run') : t('text.featured.try_out')
  end

  def featured_offer_earn_currency_text(offer, currency, display_multiplier)
    if offer.rewarded? && currency.rewarded?
      return t('text.featured.earn_currency', :amount_and_currency => "#{currency.get_visual_reward_amount(offer, display_multiplier)} #{currency.name}")
    end
    t('text.featured.download')
  end

  def featured_offer_action_text(offer)
    offer.item_type == 'App' ? t('text.featured.download') : t('text.featured.earn_now')
  end
end
