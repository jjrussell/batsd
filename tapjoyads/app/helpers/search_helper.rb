module SearchHelper
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
      :country_code       => @geoip_data[:country],
      :language_code      => params[:language_code],
      :display_multiplier => params[:display_multiplier],
      :device_name        => params[:device_name],
      :library_version    => params[:library_version])

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
end