# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :set_time_zone
  before_filter :fix_params
  before_filter :set_locale
  before_filter :reject_banned_ips

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f9a08830b0e4e7191cd93d2e02b08187'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password, :password_confirmation

private

  def verify_params(required_params, options = {})
    render_missing_text = options.delete(:render_missing_text) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    if params[:udid] == 'null' || params[:app_id] == 'todo todo todo todo'
      render :text => "missing required params", :status => 400 if render_missing_text
      return false
    end

    all_params = true
    required_params.each do |param|
      if params[param].blank?
        all_params = false
        break
      end
    end

    if render_missing_text && !all_params
      render :text => "missing required params", :status => 400
    end
    return all_params
  end

  def verify_records(required_records, options = {})
    render_missing_text = options.delete(:render_missing_text) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    required_records.each do |record|
      next unless record.nil?

      render :text => "record not found", :status => 500 if render_missing_text
      return false
    end
    true
  end

  def set_time_zone
    Time.zone = 'UTC'
  end

  def set_locale
    language_code = params[:language_code] || get_http_accept_language
    I18n.locale = nil
    if AVAILABLE_LOCALES.include?(language_code)
      I18n.locale = language_code
    elsif language_code.present? && language_code['-']
      language_code = language_code.split('-').first
      if AVAILABLE_LOCALES.include?(language_code)
        I18n.locale = language_code
      end
    end
  end

  def get_http_accept_language
    # example env[HTTP_ACCEPT_LANGUAGE] string: es,en;q=0.8;en-US;q=0.6
    language_list = request.env['HTTP_ACCEPT_LANGUAGE'].split(/\s*,\s*/).map do |l|
      l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
      l.split(';q=')
    end

    prioritized_list = language_list.sort do |x,y|
      raise "Not correctly formatted" unless x.first =~ /^[a-z\-]+$/i
      y.last.to_f <=> x.last.to_f
    end

    formatted_list = prioritized_list.map do |l|
      l.first.downcase.gsub(/-[a-z]+$/i) { |i| i.upcase }
    end

    available_list = AVAILABLE_LOCALES.map {|i| i.to_s}

    valid_list = formatted_list & available_list

    valid_list.first
  rescue # default to blank if header is malformed
    ""
  end

  def lookup_udid
    return if params[:udid].present?
    lookup_keys = []
    lookup_keys.push(params[:sha2_udid]) if params[:sha2_udid].present?
    lookup_keys.push(params[:mac_address]) if params[:mac_address].present?

    lookup_keys.each do |lookup_key|
      identifier = DeviceIdentifier.new(:key => lookup_key)
      unless identifier.new_record?
        params[:udid] = identifier.udid
        break
      end
    end
  end

  def fix_params
    downcase_param(:udid)
    downcase_param(:sha2_udid)
    downcase_param(:app_id)
    downcase_param(:campaign_id)
    downcase_param(:publisher_app_id)
    downcase_param(:publisher_user_record_id)
    downcase_param(:offer_id)
    downcase_param(:type)
    set_param(:udid, :DeviceTag, true)
    set_param(:app_id, :AppID, true)
    set_param(:device_os_version, :DeviceOSVersion)
    set_param(:device_type, :DeviceType)
    set_param(:library_version, :ConnectLibraryVersion)
    set_param(:app_version, :AppVersion)
    set_param(:campaign_id, :CampaignID, true)
    set_param(:campaign_id, :AdCampaignID, true)
    set_param(:advertiser_app_id, :AdvertiserAppID, true)
    set_param(:publisher_app_id, :AppID, true)
    set_param(:publisher_user_id, :PublisherUserRecordID)
    set_param(:campaign_id, :AdImpressionID, true)
    set_param(:offer_id, :CachedOfferID, true)
    set_param(:type, :Type, true)
    set_param(:publisher_user_id, :PublisherUserID)
    set_param(:start, :Start)
    set_param(:max, :Max)
    set_param(:virtual_good_id, :VirtualGoodID)
    set_param(:language_code, :language)
    params[:mac_address] = params[:mac_address].downcase.gsub(/:/,"") if params[:mac_address].present?
  end

  def downcase_param(p)
    params[p] = params[p].downcase if params[p]
  end

  def set_param(to, from, lower = false)
    if (not params[to]) && params[from]
      params[to] = params[from]
      params[to] = params[to].downcase.strip if lower
    end
  end

  def get_ip_address
    @request_ip_address ||= (request.headers['X-Forwarded-For'] || request.remote_ip).gsub(/,.*$/, '')
  end

  def get_geoip_data
    return @cached_geoip_data if @cached_geoip_data.present?

    @cached_geoip_data = {}
    ip_address = params[:device_ip] || get_ip_address

    begin
      geo_struct = GEOIP.city(ip_address)
    rescue Exception => e
      geo_struct = nil
    end

    if geo_struct.present?
      @cached_geoip_data[:country]     = geo_struct[:country_code2]
      @cached_geoip_data[:continent]   = geo_struct[:continent_code]
      @cached_geoip_data[:region]      = geo_struct[:region_name]
      @cached_geoip_data[:city]        = geo_struct[:city_name]
      @cached_geoip_data[:postal_code] = geo_struct[:postal_code]
      @cached_geoip_data[:lat]         = geo_struct[:latitude]
      @cached_geoip_data[:long]        = geo_struct[:longitude]
      @cached_geoip_data[:area_code]   = geo_struct[:area_code]
      @cached_geoip_data[:dma_code]    = geo_struct[:dma_code]
    end
    @cached_geoip_data[:user_country_code]    = params[:country_code]
    @cached_geoip_data[:carrier_country_code] = params[:carrier_country_code]
    @cached_geoip_data
  end

  def geoip_location
    "#{get_geoip_data[:city]}, #{get_geoip_data[:region]}, #{get_geoip_data[:country]} (#{get_ip_address})"
  end

  def reject_banned_ips
    render :text => '' if BANNED_IPS.include?(get_ip_address)
  end

  def log_activity(object, options={})
    included_methods = options.delete(:included_methods) { [] }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    @request_id ||= UUIDTools::UUID.random_create.to_s
    @activity_logs ||= []

    activity_log                  = ActivityLog.new({ :load => false })
    activity_log.request_id       = @request_id
    activity_log.user             = 'system'
    activity_log.controller       = params[:controller]
    activity_log.action           = params[:action]
    activity_log.included_methods = included_methods
    activity_log.object           = object
    activity_log.ip_address       = get_ip_address

    if self.respond_to?(:current_user)
      activity_log.user           = current_user.username
      activity_log.user_id        = current_user.id
    end

    @activity_logs << activity_log
  end

  def save_activity_logs(serial_save = false)
    if @activity_logs.present?
      @activity_logs.each do |activity_log|
        activity_log.finalize_states
        serial_save ? activity_log.serial_save : activity_log.save
      end
      @activity_logs = []
    end
  end

  def determine_link_affiliates
    if App::TRADEDOUBLER_COUNTRIES.include?(get_geoip_data[:country])
      @itunes_link_affiliate = 'tradedoubler'
    else
      @itunes_link_affiliate = 'linksynergy'
    end
  end

  def choose_experiment
    params[:exp] = Experiments.choose(params[:udid]) unless params[:exp].present?
  end

  def build_test_offer(publisher_app)
    test_offer = Offer.new(
      :item_id            => publisher_app.id,
      :item_type          => 'TestOffer',
      :name               => 'Test Offer (Visible to Test Devices)',
      :third_party_data   => publisher_app.id,
      :price              => 0,
      :reward_value       => 100)
    test_offer.id = publisher_app.id
    test_offer
  end

  def build_test_video_offer(publisher_app)
    test_video_offer = VideoOffer.new(
      :name       => 'Test Video Offer (Visible to Test Devices)',
      :partner_id => publisher_app.partner_id,
      :video_url  => 'https://s3.amazonaws.com/tapjoy/videos/src/test_video.mp4')
    test_video_offer.id = 'test_video'

    primary_offer = Offer.new(
      :item_id          => 'test_video',
      :name             => 'Test Video Offer (Visible to Test Devices)',
      :url              => 'https://s3.amazonaws.com/tapjoy/videos/src/test_video.mp4',
      :reward_value     => 100,
      :third_party_data => '')
    primary_offer.id = 'test_video'

    test_video_offer.primary_offer           = primary_offer
    test_video_offer.primary_offer.item_type = 'TestVideoOffer'
    test_video_offer
  end

  def decrypt_data_param
    return unless params[:data].present?

    begin
      data = ObjectEncryptor.decrypt(params[:data])
      params.merge!(data)
    rescue OpenSSL::Cipher::CipherError, TypeError => e
      render :text => 'bad request', :status => 400
      return false
    end

    true
  end

  def set_publisher_user_id
    params[:publisher_user_id] = params[:udid] if params[:publisher_user_id].blank?
  end
end
