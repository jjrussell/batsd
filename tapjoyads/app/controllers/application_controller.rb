# Multiple STI subclasses in one file needs this line to be findable in development mode
require_dependency 'review_moderation_vote'
require_dependency 'library_version'
require_dependency 'earth'


# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  helper_method :geoip_data, :downcase_param, :library_version

  before_filter :check_uri if MACHINE_TYPE == 'website'
  before_filter :force_utc
  before_filter :set_readonly_db
  before_filter :fix_params
  before_filter :set_locale
  before_filter :reject_banned_ips

  before_filter { ActiveRecordDisabler.disable_queries! } unless Rails.env.production?

  # TODO: DO NOT LEAVE THIS ON IN PRODUCTION
  # after_filter :store_response

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f9a08830b0e4e7191cd93d2e02b08187'

  def set_readonly_db
    ActiveRecord::Base.readonly = Rails.configuration.db_readonly_hostnames.include?(request.host_with_port)
  end

  private

  @@available_locales = I18n.available_locales.to_set

  def params_for_device_creation
    Device::IDENTIFIERS_FOR_CREATE.select {|identifier| params.include? identifier}
  end

  def get_device_key
    params[:tapjoy_device_id] || params[:udid] || params[:mac_address]
  end

  def which_to_slice
    %w(tapjoy_device_id udid mac_address).each { |key| return key.to_sym if params[key].present? }
  end

  def store_response
    if response.content_type == 'application/json'
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        key = [
          'rails3',
          'responses',
          request.path_parameters[:controller],
          request.path_parameters[:action],
        ].join('/') + '.json'
        $redis.sadd key, response.body
      end
    elsif response.content_type == 'application/xml'
      begin
        ::XmlSimple.xml_in(response.body)
      rescue ArgumentError
        key = [
          'rails3',
          'responses',
          request.path_parameters[:controller],
          request.path_parameters[:action],
        ].join('/') + '.xml'
        $redis.sadd key, response.body
      end
    end
  end

  def verify_params(*args)
    options = args.extract_options!
    required_params = args.flatten
    render_missing_text = options.delete(:render_missing_text) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    missing_params = required_params.select{ |param| params[param].blank? } || params[:udid] == 'null'
    render :text => "missing parameters: #{missing_params.join(', ')}", :status => 400 if render_missing_text && missing_params.any?
    !missing_params.any?
  end

  def verify_device_info(options = {})
    render_missing_text = options.delete(:render_missing_text) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    has_device_info = DeviceIdentifier::ALL_IDENTIFIERS.any? {|identifier| params.include? identifier}
    render :text => 'missing required device params', :status => 400 if render_missing_text && !has_device_info
    has_device_info
  end

  def verify_records(*args)
    options = args.extract_options!
    required_records = args.flatten
    render_missing_text = options.delete(:render_missing_text) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    record_missing = required_records.any?( &:nil? )
    render :text => 'record not found', :status => 400 if render_missing_text && record_missing
    !record_missing
  end

  def force_utc
    Time.zone = 'UTC'
  end

  def set_locale
    I18n.locale = get_locale || I18n.default_locale
  end

  # detect the locale info from the params and return the proper one
  #
  # @return [String] Locale detected from the language_code param
  def get_locale
    language_code_str, language_code = nil, nil
    if params[:language_code].present?
      language_code_str = params[:language_code].downcase
      language_code = language_code_str.to_sym

      if !@@available_locales.include?(language_code)
        if language_code_str['-']
          language_code_str = language_code_str.split('-').first
          language_code = language_code_str.to_sym
        else
          language_code_str, language_code = nil, nil
        end
      end

      if language_code_str.present? && params[:country_code].present?
        locale_country_str = "#{language_code_str}-#{params[:country_code].downcase}"
        locale_country_code = locale_country_str.to_sym
        if @@available_locales.include?(locale_country_code)
          language_code = locale_country_code
        end
      end
    elsif params[:country_code].present?
      locale_country_code = params[:country_code].downcase.to_sym
      if @@available_locales.include?(locale_country_code)
        language_code = locale_country_code
      end
    end

    language_code
  end

  def find_or_create_device(allow_temp = false)
    if @lookup_device
      set_tapjoy_id and return @lookup_device
    elsif params[:can_create_new_device]
      @lookup_device = Device.new
      set_tapjoy_id and return @lookup_device
    elsif allow_temp && params[:temporary_device_id]
      @lookup_device = Device.new(:key => params[:temporary_device_id], :is_temporary => allow_temp)
      set_tapjoy_id and return @lookup_device
    else
      return nil # We couldnt find the device and/or create a temp one
    end
  end

  def lookup_device(set_temporary_device = false)
    params[:udid] = nil if IGNORED_UDIDS.include?(params[:udid])

    return if device_exists

    @lookup_device = DeviceIdentifier.find_device_from_params(params)

    return if device_exists

    params[:can_create_new_device] = params_for_device_creation.any?

    if set_temporary_device && !params[:can_create_new_device]
      lookup_params = params.slice(*DeviceIdentifier::ALL_IDENTIFIERS)
      params[:temporary_device_id] = lookup_params.first.second if lookup_params.any?
    end
  end

  def device_exists
    @lookup_device.present? ? params[:tapjoy_device_id] ||= @lookup_device.key : nil
  end

  def set_tapjoy_id
    params[:tapjoy_device_id] ||= @lookup_device.key
  end

  def fix_params
    downcase_param(:udid)
    downcase_param(:sha2_udid)
    downcase_param(:sha1_udid)
    downcase_param(:sha1_mac_address)
    downcase_param(:open_udid)
    downcase_param(:advertising_id)
    downcase_param(:app_id)
    downcase_param(:campaign_id)
    downcase_param(:publisher_app_id)
    downcase_param(:publisher_user_record_id)
    downcase_param(:offer_id)
    downcase_param(:type)
    downcase_param(:library_version)
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
    params[p] = params[p].downcase if params[p].is_a?(String)
  end

  def set_param(to, from, lower = false)
    if (not params[to]) && params[from]
      params[to] = params[from]
      params[to] = params[to].downcase.strip if lower
    end
  end

  def ip_address
    return @cached_ip_address if @cached_ip_address.present?
    remote_ip = (request.headers['X-Forwarded-For'] || request.remote_ip)
    @cached_ip_address = remote_ip.gsub(/,.*$/, '')
  end

  def geoip_data
    return @cached_geoip_data if @cached_geoip_data.present?

    @cached_geoip_data = {}

    unless @server_to_server && params[:device_ip].blank?
      geo_struct = GEOIP.city(params[:device_ip] || ip_address) rescue nil
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
    end
    @cached_geoip_data[:user_country_code]    = params[:country_code].present? ? params[:country_code].to_s.upcase : nil
    @cached_geoip_data[:carrier_country_code] = params[:carrier_country_code].present? ? params[:carrier_country_code].to_s.upcase : nil

    # TO REMOVE - we ideally should always be using the priority: carrier_country_code -> geoip_country -> user_country_code
    # However, many of our server-to-server publishers are integrated incorrectly, so we have to switch the priority until they all
    # fix their integration by properly sending us `library_version=server&device_ip=<ip_address>`.
    # We will still prioritize geoip_country over user_country_code for Asian locations, due to potential fraud.
    if @cached_geoip_data[:continent] == 'AS'
      @cached_geoip_data[:primary_country] = params[:primary_country] || @cached_geoip_data[:carrier_country_code] || @cached_geoip_data[:country] || @cached_geoip_data[:user_country_code]
    else
      @cached_geoip_data[:primary_country] = params[:primary_country] || @cached_geoip_data[:carrier_country_code] || @cached_geoip_data[:user_country_code] || @cached_geoip_data[:country]
    end
    @cached_geoip_data
  end

  def geoip_location
    "#{geoip_data[:city]}, #{geoip_data[:region]}, #{geoip_data[:country]} (#{ip_address})"
  end

  def reject_banned_ips
    render :text => '' if BANNED_IPS.include?(ip_address)
  end

  def reject_banned_udids
    render(:json => { :success => false, :error => ['Bad UDID'] }, :status => 403) if BANNED_UDIDS.include?(params[:udid])
  end

  def reject_banned_advertising_ids
    render(:json => { :success => false, :error => ['Bad Advertising ID'] }, :status => 403) if BANNED_ADVERTISING_IDS.include?(params[:advertising_id])
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
    activity_log.ip_address       = ip_address

    if self.respond_to?(:current_user)
      activity_log.user           = current_user.username
      activity_log.user_id        = current_user.id
    end

    @activity_logs << activity_log
  end

  def save_activity_logs
    if @activity_logs.present?
      @activity_logs.each do |activity_log|
        activity_log.finalize_states
        activity_log.save
      end
      @activity_logs = []
    end
  end

  def choose_experiment(experiment)
    params[:exp] = Experiments.choose(get_device_key, :experiment => experiment) unless params[:exp].present?
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

  def publisher_params
    params[:udid] || params[:mac_address]
  end

  def set_publisher_user_id
    params[:publisher_user_id] = publisher_params if params[:publisher_user_id].blank?
  end

  def sdkless_supported?
    library_version.sdkless_integration? && (params[:sdk_type] == 'offers' || params[:sdk_type] == 'virtual_goods')
  end

  def library_version
    @library_version ||= LibraryVersion.new(params[:library_version])
  end

  def generate_verifier(more_data = [])
    hash_bits = [
      params[:app_id],
      request.query_parameters[:udid] || params[:mac_address],
      params[:timestamp],
      App.find_in_cache(params[:app_id]).secret_key
    ] + more_data
    Digest::SHA256.hexdigest(hash_bits.join(':'))
  end

  # TODO make this more general so nobody needs to go WebRequest.new in a controller -KB
  def generate_web_request
    if params[:source] == 'tj_games' || params[:source] == 'tj_display'
      wr_path = 'tjm_offers'
    elsif params[:source] == 'featured'
      wr_path = 'featured_offer_requested'
    else
      wr_path = 'offers'
    end
    web_request = WebRequest.new(:time => @now)
    web_request.put_values(wr_path, params, ip_address, geoip_data, request.headers['User-Agent'])
    web_request.viewed_at = @now
    web_request.offerwall_start_index = @start_index
    web_request.offerwall_max_items = @max_items
    web_request.raw_url = request.url

    web_request
  end

  def update_web_request_store_name(web_request, app_id, app = nil)
    return if web_request.store_name

    platform = if params[:platform]
      params[:platform]
    elsif params[:device_type] == 'android'
      'android'
    elsif app
      app.platform
    elsif app_id
      cached_app = App.find_in_cache(app_id)
      cached_app.platform if cached_app
    end

    web_request.store_name = App::PLATFORM_DETAILS['android'][:default_sdk_store_name] if platform == 'android'
  end

  def device_type
    @device_type ||= HeaderParser.device_type(request.user_agent)
  end

  def os_version
    @os_version ||= HeaderParser.os_version(request.user_agent)
  end

  def check_uri
    redirect_to request.protocol + "www." + request.host_with_port + request.fullpath if !/^www/.match(request.host)
  end
end
