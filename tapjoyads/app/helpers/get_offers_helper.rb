module GetOffersHelper
  
  def get_previous_link
    return nil if @start_index == 0
    
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['start'] = [@start_index - @max_items, 0].max
    url = "/get_offers/webpage?data=#{SymmetricCrypto.encrypt_object(tmp_params, SYMMETRIC_CRYPTO_SECRET)}"
    link_to("<div class='arrow'></div>#{t('text.offerwall.previous', :items => @max_items)}", url, :onclick => "this.className = 'clicked';")
  end
  
  def get_next_link
    return nil if @more_data_available < 1
    
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['start'] = @start_index + @max_items
    url = "/get_offers/webpage?data=#{SymmetricCrypto.encrypt_object(tmp_params, SYMMETRIC_CRYPTO_SECRET)}"
    link_to("<div class='arrow'></div>#{t('text.offerwall.next', :items => [@more_data_available, @max_items].min)}", url, :onclick => "this.className = 'clicked';")
  end
  
  def get_next_link_json
    return nil if @more_data_available < 1
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['json'] = "1"
    "/get_offers?data=#{SymmetricCrypto.encrypt_object(tmp_params, SYMMETRIC_CRYPTO_SECRET)}"
  end
  
  def get_currency_link(currency)
    tmp_params = params.reject { |k, v| k == 'controller' || k == 'action' }
    tmp_params['currency_id'] = currency.id
    url = "/get_offers/webpage?data=#{SymmetricCrypto.encrypt_object(tmp_params, SYMMETRIC_CRYPTO_SECRET)}"
    link_to(currency.name, url, :class => currency.id == @currency.id ? 'current' : '')
  end
  
  def get_click_url(offer)
    click_url = offer.get_click_url(
      :publisher_app      => @publisher_app,
      :publisher_user_id  => params[:publisher_user_id],
      :udid               => params[:udid],
      :currency_id        => @currency.id,
      :source             => params[:source],
      :app_version        => params[:app_version],
      :viewed_at          => @now,
      :exp                => params[:exp],
      :country_code       => @geoip_data[:country],
      :language_code      => params[:language_code],
      :display_multiplier => params[:display_multiplier],
      :device_name        => params[:device_name])
        
    if offer.item_type == 'VideoOffer'
      "tjvideo://video_id=#{offer.id}&amount=#{@currency.get_visual_reward_amount(offer, params[:display_multiplier])}&currency_name=#{URI::escape(@currency.name)}&click_url=#{click_url}"
    else
      click_url
    end
  end

  def get_fullscreen_ad_url(offer)
    offer.get_fullscreen_ad_url(
        :publisher_app      => @publisher_app,
        :publisher_user_id  => params[:publisher_user_id],
        :udid               => params[:udid],
        :currency_id        => @currency.id,
        :source             => params[:source],
        :app_version        => params[:app_version],
        :viewed_at          => @now,
        :exp                => params[:exp],
        :country_code       => @geoip_data[:country],
        :display_multiplier => params[:display_multiplier])
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

  def link_to_missing_currency
    support_params = [ 'app_id', 'currency_id', 'udid', 'device_type', 'publisher_user_id', 'language_code' ].inject({}) { |h,k| h[k] = params[k]; h }
    link_to(t('text.offerwall.missing_currency', :currency => @currency.name),
      new_support_request_path(support_params))
  end

end
