class Device < SimpledbShardedResource
  self.num_domains = NUM_DEVICES_DOMAINS

  attr_reader :parsed_apps, :is_temporary

  self.sdb_attr :apps, :type => :json, :default_value => {}
  self.sdb_attr :is_jailbroken, :type => :bool, :default_value => false
  self.sdb_attr :country
  self.sdb_attr :internal_notes
  self.sdb_attr :survey_answers, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :opted_out, :type => :bool, :default_value => false
  self.sdb_attr :opt_out_offer_types, :replace => false, :force_array => true
  self.sdb_attr :banned, :type => :bool, :default_value => false
  self.sdb_attr :last_run_time_tester, :type => :bool, :default_value => false
  self.sdb_attr :publisher_user_ids, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :display_multipliers, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :product
  self.sdb_attr :version
  self.sdb_attr :mac_address
  self.sdb_attr :open_udid
  self.sdb_attr :android_id
  self.sdb_attr :platform
  self.sdb_attr :is_papayan, :type => :bool, :default_value => false
  self.sdb_attr :all_packages, :type => :json, :default_value => []
  self.sdb_attr :current_packages, :type => :json, :default_value => []
  self.sdb_attr :sdkless_clicks, :type => :json, :default_value => {}
  self.sdb_attr :recent_skips, :type => :json, :default_value => []
  self.sdb_attr :recent_click_hashes, :type => :json, :default_value => []

  SKIP_TIMEOUT = 4.hours
  MAX_SKIPS    = 100
  RECENT_CLICKS_RANGE = 30.days

  # We want a consistent "device id" to report to partners/3rd parties,
  # but we don't want to reveal internal IDs. We also want to make
  # the values unique between partners so that no 'collusion' can
  # take place.
  def self.advertiser_device_id(udid, advertiser_partner_id)
    Digest::MD5.hexdigest("#{udid}.#{advertiser_partner_id}" + UDID_SALT)
  end

  def advertiser_device_id(advertiser_partner_id)
    Device.advertiser_device_id(key, advertiser_partner_id)
  end

  def mac_address=(new_value)
    new_value = new_value ? new_value.downcase.gsub(/:/,"") : ''
    @create_device_identifiers ||= (self.mac_address != new_value)
    put('mac_address', new_value)
  end

  def open_udid=(new_value)
    @create_device_identifiers ||= (self.open_udid != new_value)
    put('open_udid', new_value)
  end

  def android_id=(new_value)
    @create_device_identifiers ||= (self.android_id != new_value)
    put('android_id', new_value)
  end

  def initialize(options = {})
    @is_temporary = options.delete(:is_temporary) { false }
    super({ :load_from_memcache => true }.merge(options))
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICES_DOMAINS
    "devices_#{domain_number}"
  end

  def tjgames_registration_click_key
    "#{key}.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
  end

  def after_initialize
    @create_device_identifiers = is_new
    @retry_save_on_fail = is_new
    fix_app_json
    fix_publisher_user_ids_json
    fix_display_multipliers_json
    load_data_from_temporary_device if @is_temporary
  end

  def handle_connect!(app_id, params)
    return [] unless app_id =~ APP_ID_FOR_DEVICES_REGEX

    now = Time.zone.now
    path_list = []

    self.mac_address = params[:mac_address] if params[:mac_address].present?
    self.android_id = params[:android_id] if params[:android_id].present?

    if params[:open_udid].present?
      open_udid_was = self.open_udid
      self.open_udid = params[:open_udid]
      path_list << 'open_udid_change' if open_udid_was.present? && open_udid_was != open_udid
    end

    is_jailbroken_was = is_jailbroken
    country_was = country
    last_run_time_was = last_run_time(app_id)

    if last_run_time_was.nil?
      path_list.push('new_user')
      last_run_time_was = Time.zone.at(0)

      # mark papaya new users as jailbroken
      if app_id == 'e96062c5-45f0-43ba-ae8f-32bc71b72c99'
        self.is_jailbroken = true
      end
    end

    offset = @key.matz_silly_hash % 1.day
    adjusted_now = now - offset
    adjusted_lrt = last_run_time_was - offset
    if adjusted_now.year != adjusted_lrt.year || adjusted_now.yday != adjusted_lrt.yday
      path_list.push('daily_user')
    end
    if adjusted_now.year != adjusted_lrt.year || adjusted_now.month != adjusted_lrt.month
      path_list.push('monthly_user')
    end

    @parsed_apps[app_id] = "%.5f" % now.to_f
    self.apps = @parsed_apps

    if params[:lad].present?
      if params[:lad] == '0'
        self.is_jailbroken = false
      else
        self.is_jailbroken = true unless app_id == 'f4398199-6316-4680-9acf-d6dbf7f8104a' # Feed Al has inaccurate jailbroken detection
      end
    end

    if params[:country].present?
      if self.country.present? && self.country != params[:country]
        Notifier.alert_new_relic(DeviceCountryChanged, "Country for udid: #{@key} changed from #{self.country} to #{params[:country]}", nil, params)
      end
      self.country = params[:country]
    end

    if (last_run_time_tester? || is_jailbroken_was != is_jailbroken || country_was != country || path_list.include?('daily_user') || @create_device_identifiers)
      save
    end

    path_list
  end

  def set_last_run_time(app_id)
    retry_save_on_fail = true if @parsed_apps[app_id].nil?
    @parsed_apps[app_id] = "%.5f" % Time.zone.now.to_f
    self.apps = @parsed_apps
  end

  def set_last_run_time!(app_id)
    set_last_run_time(app_id)
    save
  end

  def has_app?(app_id)
    @parsed_apps[app_id].present?
  end

  def last_run_time(app_id)
    last_run_timestamp = @parsed_apps[app_id]

    if last_run_timestamp.is_a?(Array)
      last_run_timestamp = last_run_timestamp[0]
    end

    last_run_timestamp.present? ? Time.zone.at(last_run_timestamp.to_f) : nil
  end

  def unset_last_run_time!(app_id)
    @parsed_apps.delete(app_id)
    self.apps = @parsed_apps
    save!
  end

  def set_publisher_user_id(app_id, publisher_user_id)
    parsed_publisher_user_ids = publisher_user_ids
    return if parsed_publisher_user_ids[app_id] == publisher_user_id

    parsed_publisher_user_ids[app_id] = publisher_user_id
    self.publisher_user_ids = parsed_publisher_user_ids
  end

  def set_publisher_user_id!(app_id, publisher_user_id)
    set_publisher_user_id(app_id, publisher_user_id)
    save if changed?
  end

  def set_display_multiplier(app_id, display_multi)
    parsed_display_multiplier = display_multipliers
    return if parsed_display_multiplier[app_id] == display_multi

    parsed_display_multiplier[app_id] = display_multi
    self.display_multipliers = parsed_display_multiplier
  end

  def set_display_multiplier!(app_id, display_multi)
    set_display_multiplier(app_id, display_multi)
    save if changed?
  end

  def self.normalize_device_type(device_type_param)
    return nil if device_type_param.nil?

    case device_type_param.downcase
    when /iphone/
      'iphone'
    when /ipod/, /itouch/
      'itouch'
    when /ipad/
      'ipad'
    when /android/
      'android'
    when /windows|wince/
      'windows'
    end
  end

  def last_app_run
    return nil if @parsed_apps.empty?
    @parsed_apps.max_by { |k,v| v }.first
  end

  def recommendations(options = {})
    RecommendationList.new(options.merge(:device => self)).apps
  end

  def gamers
    @gamers ||= Gamer.find(:all, :joins => [:gamer_devices], :conditions => ['gamer_devices.device_id = ?', key])
  end

  def update_package_names!(package_names)
    return if ((package_names - current_packages) | (current_packages - package_names)).empty?
    self.all_packages |= package_names
    self.current_packages = package_names
    save!
  end

  def save(options = {})
    create_identifiers = options.delete(:create_identifiers) { true }
    if @is_temporary
      temp_device = TemporaryDevice.new(:key => self.key)
      temp_device.apps = temp_device.apps.merge(self.parsed_apps)
      temp_device.publisher_user_ids = temp_device.publisher_user_ids.merge(self.publisher_user_ids)
      temp_device.display_multipliers = temp_device.display_multipliers.merge(self.display_multipliers)
      temp_device.save
      return
    end

    remove_old_skips
    return_value = super({ :write_to_memcache => true }.merge(options))
    Sqs.send_message(QueueNames::CREATE_DEVICE_IDENTIFIERS, {'device_id' => key}.to_json) if @create_device_identifiers && create_identifiers
    @create_device_identifiers = false
    return_value
  end

  def self.formatted_mac_address(mac_address)
    mac_address.to_s.empty? ? nil : mac_address.strip.upcase.scan(/.{2}/).join(':')
  end

  def create_identifiers!
    all_identifiers = [ Digest::SHA2.hexdigest(key) ]
    all_identifiers << Digest::SHA1.hexdigest(key)
    all_identifiers.push(open_udid) if self.open_udid.present?
    all_identifiers.push(android_id) if self.android_id.present?
    if self.mac_address.present?
      all_identifiers.push(mac_address)
      all_identifiers.push(Digest::SHA1.hexdigest(Device.formatted_mac_address(mac_address)))
    end
    all_identifiers.each do |identifier|
      device_identifier = DeviceIdentifier.new(:key => identifier)
      next if device_identifier.udid == key
      if device_identifier.udid? && device_identifier.udid != key && Rails.env.production?
        timestamp = Time.zone.now
        redis_key = "device_identifier.#{timestamp.to_f.to_s}"
        $redis.setex(redis_key, 30.days, {:identifier => identifier, :new_udid => key, :old_udid => device_identifier.udid}.to_json)
        $redis.sadd("device_identifier", redis_key)
        $redis.sadd("device_identifier.#{timestamp.to_i / 1.week}", redis_key)
      end
      device_identifier.udid = key
      device_identifier.save!
    end
    merge_temporary_devices!(all_identifiers)
  end

  def copy_mac_address_device!
    return if mac_address.nil? || key == mac_address
    mac_device = Device.new(:key => mac_address, :consistent => true)
    return if mac_device.new_record?

    Currency.find_each(:conditions => ["id IN (?)", mac_device.parsed_apps.keys]) do |c|
      app_id = c.id
      mac_pp = PointPurchases.new(:key => "#{mac_address}.#{app_id}", :consistent => true)
      next if mac_pp.new_record?

      udid_pp = PointPurchases.new(:key => "#{key}.#{app_id}", :consistent => true)
      udid_pp.points = mac_pp.points
      udid_pp.virtual_goods = mac_pp.virtual_goods
      udid_pp.save!
      mac_pp.delete_all
    end

    self.apps = mac_device.parsed_apps.merge(@parsed_apps)
    self.publisher_user_ids = mac_device.publisher_user_ids.merge(publisher_user_ids)
    save!
    mac_device.delete_all
  end

  def handle_sdkless_click!(offer, now)
    if offer.sdkless?
      temp_sdkless_clicks = sdkless_clicks

      hash_key = offer.third_party_data
      if offer.get_platform == 'iOS'
        hash_key = offer.app_protocol_handler.present? ? offer.app_protocol_handler : "tjc#{offer.third_party_data}"
      end

      temp_sdkless_clicks[hash_key] = { 'click_time' => now.to_i, 'item_id' => offer.item_id }
      temp_sdkless_clicks.reject! { |key, value| value['click_time'] <= (now - 2.days).to_i }
      self.sdkless_clicks = temp_sdkless_clicks
      @retry_save_on_fail = true
      save
    end
  end

  def self.device_type_to_platform(type)
    case type
    when 'iphone', 'ipad', 'ipod' then 'ios'
    else type
    end
  end

  # For use within TJM (since dashboard URL helpers aren't available within TJM)
  def dashboard_device_info_tool_url
    uri = URI.parse(DASHBOARD_URL)
    "#{uri.scheme}://#{uri.host}/tools/device_info?udid=#{self.key}"
  end

  def recently_skipped?(offer_id)
    longest_time = Time.zone.now - Device::SKIP_TIMEOUT
    self.recent_skips.any? { |skip| (skip[0] == offer_id) && (Time.zone.parse(skip[1]).to_i  >= longest_time.to_i)}
  end

  def add_skip(offer_id)
    temp = recent_skips
    temp.unshift([offer_id, Time.zone.now])
    self.recent_skips = temp.first(Device::MAX_SKIPS)
  end

  def remove_old_skips(time = Device::SKIP_TIMEOUT)
    temp = self.recent_skips
    self.recent_skips = temp.take_while { |skip| Time.zone.now - Time.parse(skip[1]) <= time }
  end

  def recent_clicks(start_time_at = Time.zone.now-RECENT_CLICKS_RANGE, end_time_at = Time.zone.now)
    clicks = []
    self.recent_click_hashes.each do |recent_click_hash|
      click = Click.find(recent_click_hash['id'])
      next unless click
      clicked_at = click.clicked_at.to_f
      cutoff = (clicked_at > end_time_at || clicked_at < start_time_at)
      clicks << click unless (cutoff || click.tapjoy_games_invitation_primary_click?)
    end
    clicks
  end

  def add_click(click)
    click_id = click.id
    temp_click_hashes = self.recent_click_hashes
    end_period = (Time.now - RECENT_CLICKS_RANGE).to_f

    shift_index = 0
    temp_click_hashes.each_with_index do |temp_click_hash, i|
      if temp_click_hash['clicked_at'] < end_period
        shift_index = i+1
      else
        break
      end
    end
    temp_click_hashes.shift(shift_index)

    temp_click_hashes << {'id' => click.id, 'clicked_at' => click.clicked_at.to_f}
    self.recent_click_hashes = temp_click_hashes
    @retry_save_on_fail = true
    save
  end

  private

  def merge_temporary_devices!(all_identifiers)
    orig_apps = self.parsed_apps.clone
    all_identifiers.each do |identifier|
      temp_device = TemporaryDevice.find(identifier)
      if temp_device
        @parsed_apps.merge!(temp_device.apps)
        self.publisher_user_ids = temp_device.publisher_user_ids.merge(publisher_user_ids)
        self.display_multipliers = temp_device.display_multipliers.merge(display_multipliers)
        temp_device.delete_all
      end
    end
    self.apps = @parsed_apps

    save!(:create_identifiers => false) unless orig_apps == self.parsed_apps
  end

  def load_data_from_temporary_device
    temp_device = TemporaryDevice.new(:key => self.key)
    @parsed_apps = temp_device.apps.merge(self.parsed_apps)
    self.publisher_user_ids = temp_device.publisher_user_ids.merge(self.publisher_user_ids)
    self.display_multipliers = temp_device.display_multipliers.merge(self.display_multipliers)
    self.apps = @parsed_apps
  end

  def fix_parser_error(attribute, search_from = :left)
    str = get(attribute)
    if search_from == :right
      pos = str.rindex('}')
    else
      pos = str.index('}')
    end
    if pos.nil?
      pos = str.rindex(',')
      removed = str.slice!(pos..-1)
      str += '}'
    else
      removed = str.slice!(pos+1..-1)
    end
    str
  end

  def fix_app_json
    begin
      @parsed_apps = apps
    rescue JSON::ParserError
      self.apps = @parsed_apps = JSON.parse(fix_parser_error('apps'))
    end
  end

  def fix_publisher_user_ids_json
    begin
      publisher_user_ids
    rescue JSON::ParserError
      self.publisher_user_ids = JSON.parse(fix_parser_error('publisher_user_ids', :right))
    end
  end

  def fix_display_multipliers_json
    begin
      display_multipliers
    rescue JSON::ParserError
      self.display_multipliers = JSON.parse(fix_parser_error('display_multipliers', :right))
    end
  end
end
