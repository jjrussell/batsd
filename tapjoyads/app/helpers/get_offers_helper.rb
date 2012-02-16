module GetOffersHelper

  def get_next_link_json
    return nil if @more_data_available < 1
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['json'] = "1"
    "/get_offers?data=#{ObjectEncryptor.encrypt(tmp_params)}"
  end

  def get_currency_link(currency)
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['currency_id'] = currency.id
    url = "/get_offers/webpage?data=#{ObjectEncryptor.encrypt(tmp_params)}"
    link_to(currency.name, url)
  end

  def get_click_url(offer)
    click_url = offer.click_url(
      :publisher_app      => @publisher_app,
      :publisher_user_id  => params[:publisher_user_id],
      :udid               => params[:udid],
      :currency_id        => @currency.id,
      :source             => params[:source],
      :app_version        => params[:app_version],
      :viewed_at          => @now,
      :exp                => params[:exp],
      :primary_country    => get_geoip_data[:primary_country],
      :language_code      => params[:language_code],
      :display_multiplier => params[:display_multiplier],
      :device_name        => params[:device_name],
      :library_version    => params[:library_version],
      :gamer_id           => params[:gamer_id])

    if offer.item_type == 'VideoOffer' || offer.item_type == 'TestVideoOffer'
      if @publisher_app.platform == 'windows'
        prefix = "http://tjvideo.tjvideo.com/tjvideo?"
      else
        prefix = "tjvideo://"
      end
      "#{prefix}video_id=#{offer.id}&amount=#{@currency.get_visual_reward_amount(offer, params[:display_multiplier])}&currency_name=#{URI::escape(@currency.name)}&click_url=#{click_url}"
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
        :primary_country    => get_geoip_data[:primary_country],
        :display_multiplier => params[:display_multiplier],
        :library_version    => params[:library_version],
        :language_code      => params[:language_code])
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

end
