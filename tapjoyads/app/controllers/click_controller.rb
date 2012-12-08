class ClickController < ApplicationController
  layout 'iphone'

  prepend_before_filter :decrypt_data_param
  before_filter :reengagement_setup, :only => [ :reengagement ]
  before_filter :setup
  before_filter :validate_click, :except => [ :test_offer, :test_video_offer ]
  before_filter :determine_link_affiliates, :only => :app

  after_filter :save_web_request, :except => [ :test_offer, :test_video_offer ]

  def app
    create_click('install')
    handle_pay_per_click
    @device.handle_sdkless_click!(@offer, @now)

    redirect_to(destination_url)
  end

  def determine_link_affiliates
    @itunes_link_affiliate = Linkshare.affiliate_token(geoip_data[:country])
  end

  def reengagement
    create_click('reengagement')
    handle_pay_per_click

    render :text => 'OK'
  end

  def action
    create_click('action')
    handle_pay_per_click

    redirect_to(destination_url)
  end

  def generic
    create_click('generic')
    handle_pay_per_click

    redirect_to(destination_url)
  end

  def rating
    create_click('rating')
    handle_pay_per_click

    redirect_to(destination_url)
  end

  def video
    create_click('video')
    handle_pay_per_click
    handle_multi_complete_video

    render :text => 'OK'
  end

  def survey
    create_click('survey')
    handle_pay_per_click

    redirect_to(destination_url)
  end

  def deeplink
    create_click('deeplink')
    handle_pay_per_click

    redirect_to(destination_url)
  end

  def coupon
    create_click('coupon')

    redirect_to(destination_url)
  end

  def test_offer
    publisher_app = App.find_in_cache(params[:publisher_app_id])
    return unless verify_records([ @currency, publisher_app ])

    unless @currency.has_test_device?(params[:udid] || params[:mac_address])
      raise "not a test device"
    end

    @test_offer = publisher_app.test_offer

    test_reward = Reward.new
    test_reward.type              = 'test_offer'
    test_reward.udid              = params[:udid]
    test_reward.publisher_user_id = params[:publisher_user_id]
    test_reward.currency_id       = params[:currency_id]
    test_reward.publisher_app_id  = params[:publisher_app_id]
    test_reward.advertiser_app_id = params[:publisher_app_id]
    test_reward.offer_id          = params[:publisher_app_id]
    test_reward.mac_address       = params[:mac_address]
    test_reward.currency_reward   = @currency.get_reward_amount(@test_offer)
    test_reward.publisher_amount  = 0
    test_reward.advertiser_amount = 0
    test_reward.tapjoy_amount     = 0
    test_reward.save

    Sqs.send_message(QueueNames::SEND_CURRENCY, test_reward.key)
  end

  def test_video_offer
    return unless verify_records([ @currency ])

    raise "not a test device" unless @currency.has_test_device?(params[:udid] || params[:mac_address])

    test_reward = Reward.new
    test_reward.type              = 'test_video_offer'
    test_reward.udid              = params[:udid]
    test_reward.publisher_user_id = params[:publisher_user_id]
    test_reward.currency_id       = params[:currency_id]
    test_reward.publisher_app_id  = params[:publisher_app_id]
    test_reward.advertiser_app_id = params[:publisher_app_id]
    test_reward.offer_id          = params[:publisher_app_id]
    test_reward.mac_address       = params[:mac_address]
    test_reward.currency_reward   = @currency.get_reward_amount(@offer)
    test_reward.publisher_amount  = 0
    test_reward.advertiser_amount = 0
    test_reward.tapjoy_amount     = 0
    test_reward.save

    Sqs.send_message(QueueNames::SEND_CURRENCY, test_reward.key)
  end

  private

  APPS_WITH_BAD_PUB_USER_ID = Set.new(%w(469f7523-3b99-4b42-bcfb-e18d9c3c4576 c522ed90-8764-4d3e-ba9a-0499836ee20d))

  def reengagement_setup
    params[:advertiser_app_id] = params[:publisher_app_id]
  end

  def setup
    required_params = [ :data ]
    required_params << :gamer_id if params[:advertiser_app_id] == TAPJOY_GAMES_INVITATION_OFFER_ID
    return false unless verify_params(required_params)
    @unavailable_reasons = Set.new

    @now = Time.zone.now
    if params[:offer_id] == 'test_video'
      publisher_app = App.find_in_cache(params[:publisher_app_id])
      return unless verify_records([ publisher_app ])

      @offer = publisher_app.test_video_offer.primary_offer
    else
      @offer = Offer.find_in_cache(params[:offer_id])
    end

    @currency = Currency.find_in_cache(params[:currency_id])
    required_records = [ @offer, @currency ]
    if params[:displayer_app_id].present?
      @displayer_app = App.find_in_cache(params[:displayer_app_id])
      required_records << @displayer_app
    end
    return unless verify_records(required_records)

    if !@offer.tracking_for_id && Time.zone.at(params[:viewed_at]) < (@now - 24.hours)
      build_web_request('expired_click')
      save_web_request
      @destination_url = destination_url
      @unavailable_reasons << :expired_click
      render_unavailable_offer
      return
    end

    @device = Device.new(:key => params[:udid])

    # These apps send the same publisher_user_id for every click
    if APPS_WITH_BAD_PUB_USER_ID.include?(params[:publisher_app_id])
      params[:publisher_user_id] = params[:udid]
    end
  end

  def validate_click
    unless @offer.tracking_for_id
      return if currency_disabled?
      return if offer_disabled?
      return if offer_completed?
    end
    return if recently_clicked?

    wr_path = case params[:source]
              when 'tj_games'      then 'tjm_offer_click'
              when 'tj_display'    then 'tj_display_offer_click'
              when 'featured'      then 'featured_offer_click'
              else                      'offer_click'
              end
    build_web_request(wr_path)
  end

  def currency_disabled?
    disabled = !@currency.tapjoy_enabled?
    if disabled
      build_web_request('disabled_currency')
      save_web_request
      @destination_url = destination_url
      @unavailable_reasons << :disabled_currency
      render_unavailable_offer
    end
    disabled
  end

  def offer_disabled?
    disabled = !@offer.accepting_clicks?
    if disabled
      build_web_request('disabled_offer')
      save_web_request
      @destination_url = destination_url
      @unavailable_reasons << :disabled_offer
      render_unavailable_offer
    end
    disabled
  end

  def offer_completed?
    return false if @offer.multi_complete? && !@offer.frequency_capping_reject?(@device)

    app_id_for_device = params[:advertiser_app_id]
    if @offer.item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(params[:advertiser_app_id], params[:app_version])
    end

    completed = @device.has_app?(app_id_for_device)
    unless completed || @offer.video_offer?
      publisher_user = PublisherUser.new(:key => "#{params[:publisher_app_id]}.#{params[:publisher_user_id]}")
      other_udids = publisher_user.udids - [ @device.key ]
      other_udids.each do |udid|
        device = Device.new(:key => udid)
        if device.has_app?(app_id_for_device)
          completed = true
          break
        end
      end
    end

    if completed
      build_web_request('completed_offer')
      save_web_request
      @destination_url = destination_url
      @unavailable_reasons << :completed_offer
      render_unavailable_offer
    end
    completed
  end

  def recently_clicked?
    click = Click.find(click_key)
    cutoff_time = @now - (@offer.multi_complete? && @offer.interval < 1.hour.to_i ? @offer.interval : 1.hour)
    recently_clicked = click.present? &&
                       click.clicked_at > cutoff_time &&
                       click.publisher_app_id == params[:publisher_app_id] &&
                       click.publisher_user_id == params[:publisher_user_id]

    if recently_clicked
      build_web_request('click_too_recent')
      save_web_request
      redirect_to(destination_url)
    end
    recently_clicked
  end

  def build_web_request(path)
    @web_request = WebRequest.new(:time => @now)
    @web_request.put_values(path, params, ip_address, geoip_data, request.headers['User-Agent'])
    @web_request.viewed_at = Time.zone.at(params[:viewed_at].to_f) if params[:viewed_at].present?
    @web_request.offer_is_paid = @offer.is_paid?
    @web_request.offer_daily_budget = @offer.daily_budget
    @web_request.offer_overall_budget = @offer.overall_budget
    @web_request.rewarded = @offer.rewarded_for?(@currency)
    update_web_request_store_name(@web_request, params[:publisher_app_id])
  end

  def save_web_request
    @web_request.click_key = click_key
    @web_request.save
  end

  def create_click(type)
    click = Click.new(:key => click_key)

    click.maintain_history
    click.delete('installed_at') if click.installed_at?
    click.clicked_at             = @now
    click.viewed_at              = Time.zone.at(params[:viewed_at].to_f)
    click.udid                   = params[:udid]
    click.publisher_app_id       = params[:publisher_app_id]
    click.publisher_user_id      = params[:publisher_user_id]
    click.advertiser_app_id      = params[:advertiser_app_id]
    click.displayer_app_id       = params[:displayer_app_id] || ''
    click.offer_id               = params[:offer_id]
    click.currency_id            = params[:currency_id]
    click.reward_key             = UUIDTools::UUID.random_create.to_s
    click.reward_key_2           = @displayer_app.present? ? UUIDTools::UUID.random_create.to_s : ''
    click.source                 = params[:source] || ''
    click.ip_address             = ip_address
    click.country                = params[:primary_country] || params[:country_code] || '' # TO REMOVE: stop checking for params[:country_code] at least 24 hours after rollout
    click.type                   = type
    click.advertiser_amount      = @currency.get_advertiser_amount(@offer)
    click.publisher_amount       = @currency.get_publisher_amount(@offer, @displayer_app)
    click.currency_reward        = @currency.get_reward_amount(@offer)
    click.displayer_amount       = @currency.get_displayer_amount(@offer, @displayer_app)
    click.tapjoy_amount          = @currency.get_tapjoy_amount(@offer, @displayer_app)
    click.exp                    = params[:exp]
    click.device_name            = params[:device_name]
    click.publisher_partner_id   = @currency.partner_id
    click.advertiser_partner_id  = @offer.partner_id
    click.publisher_reseller_id  = @currency.reseller_id || ''
    click.advertiser_reseller_id = @offer.reseller_id || ''
    click.spend_share            = @currency.get_spend_share(@offer)
    click.local_timestamp        = params[:local_timestamp] if params[:local_timestamp].present?
    click.mac_address            = params[:mac_address]
    click.offerwall_rank         = params[:offerwall_rank]
    click.device_type            = params[:device_type]
    click.geoip_country          = geoip_data[:country]
    click.store_name             = params[:store_name].blank? && @web_request ? @web_request.store_name : params[:store_name]
    click.cached_offer_list_id   = params[:cached_offer_list_id]
    click.cached_offer_list_type = params[:cached_offer_list_type]
    click.auditioning            = params[:auditioning]
    click.rewarded               = @offer.rewarded_for?(@currency)

    click.save

    # for third party tracking vendors
    @offer.queue_click_tracking_requests(params.slice(:udid, :publisher_app_id).merge(:ip_address => ip_address))
  end

  def handle_pay_per_click
    if @offer.pay_per_click?
      app_id_for_device = params[:advertiser_app_id]
      if @offer.item_type == 'RatingOffer'
        app_id_for_device = RatingOffer.get_id_with_app_version(params[:advertiser_app_id], params[:app_version])
      end
      @device.set_last_run_time!(app_id_for_device)

      if @offer.pay_per_click?(:ppc_on_offerwall)
        message = { :click_key => click_key, :install_timestamp => @now.to_f.to_s }.to_json
        Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
      end
    end
  end

  def destination_url
    @offer.destination_url({
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => click_key,
      :language_code         => params[:language_code],
      :itunes_link_affiliate => @itunes_link_affiliate,
      :display_multiplier    => params[:display_multiplier],
      :library_version       => params[:library_version],
      :os_version            => params[:os_version],
      :mac_address           => params[:mac_address],
      :device_click_ip       => ip_address,
      :device_type           => params[:device_type]
    })
  end

  def render_unavailable_offer
    render 'unavailable_offer', :status => 403
  end

  def click_key
    @click_key ||= @offer.format_as_click_key(params.slice(:udid, :advertiser_app_id, :gamer_id))
  end

  def handle_multi_complete_video
    app_id_for_device = params[:advertiser_app_id]
    if @offer.multi_complete? && @device.has_app?(app_id_for_device)
      @device.unset_last_run_time!(app_id_for_device)
    end
  end

end
