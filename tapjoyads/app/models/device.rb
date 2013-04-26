require_dependency 'ruby_version_independent'
require_dependency 'device_service'

class Device < SimpledbShardedResource
  include Device::Handling
  include Device::Risk
  include Device::Sdk
  include RiakMirror
  #Note the that domain name is "d" to save on bytes since device keys are in memory for Riak
  mirror_configuration :riak_bucket_name => "d", :read_from_riak => true, :queue_failed_writes => true, :disable_sdb_writes => true

  self.num_domains = NUM_DEVICES_DOMAINS

  attr_reader :parsed_apps, :is_temporary

  self.sdb_attr :apps, :type => :json, :default_value => {}                     # Formatted as { :app_id => <last_runtime>, ... }
  self.sdb_attr :apps_sdk_versions, :type => :json, :default_value => {}        # Formatted as { :app_id => '<sdk_version>', ... }
  self.sdb_attr :is_jailbroken, :type => :bool, :default_value => false
  self.sdb_attr :country
  self.sdb_attr :internal_notes
  self.sdb_attr :ban_notes, :type => :json, :default_value => []
  self.sdb_attr :survey_answers, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :opted_out, :type => :bool, :default_value => false
  self.sdb_attr :opt_out_offer_types, :replace => false, :force_array => true
  self.sdb_attr :banned, :type => :bool, :default_value => false
  self.sdb_attr :suspension_expires_at, :type => :time
  self.sdb_attr :last_run_time_tester, :type => :bool, :default_value => false
  self.sdb_attr :publisher_user_ids, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :display_multipliers, :type => :json, :default_value => {}, :cgi_escape => true
  self.sdb_attr :product
  self.sdb_attr :version
  self.sdb_attr :mac_address
  self.sdb_attr :android_id
  self.sdb_attr :idfa
  self.sdb_attr :advertising_id
  self.sdb_attr :upgraded_idfa
  self.sdb_attr :udid
  self.sdb_attr :platform
  self.sdb_attr :is_papayan, :type => :bool, :default_value => false
  self.sdb_attr :all_packages, :type => :json, :default_value => []
  self.sdb_attr :current_packages, :type => :json, :default_value => []
  self.sdb_attr :sdkless_clicks, :type => :json, :default_value => {}
  self.sdb_attr :recent_skips, :type => :json, :default_value => []
  self.sdb_attr :bookmark_tutorial_shown, :type => :bool, :default_value => false
  self.sdb_attr :pending_coupons, :type => :json, :default_value => []
  self.sdb_attr :screen_layout_size
  self.sdb_attr :mobile_country_code
  self.sdb_attr :mobile_network_code

  SKIP_TIMEOUT = 24.hours
  MAX_SKIPS    = 100
  RECENT_CLICKS_RANGE = 30.days
  MAX_OVERWRITES_TRACKED = 100000
  APP_LIMIT = 1500

  def initialize(options = {})
    @is_temporary = options.delete(:is_temporary) { false }
    super({ :load_from_memcache => true }.merge(options))
  end

  def after_initialize
    @create_device_identifiers = is_new
    @retry_save_on_fail = is_new
    fix_app_json
    fix_publisher_user_ids_json
    fix_display_multipliers_json
    load_data_from_temporary_device if @is_temporary
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

    clear_lru_apps if self.apps.count > APP_LIMIT # Keep simpledb from exploding everywhere
    remove_old_skips
    delete_extra_attributes('recent_click_hashes')    # remove obsolete sdb_attr
    was_new_record = self.new_record?
    return_value = super({ :write_to_memcache => true }.merge(options))
    queue_message = {'device_id' => key}.to_json
    Sqs.send_message(QueueNames::NEW_ADVERTISING_IDS, queue_message) if was_new_record && advertising_id_device?
    Sqs.send_message(QueueNames::CREATE_DEVICE_IDENTIFIERS, queue_message) if @create_device_identifiers && create_identifiers && !advertising_id_device?
    @create_device_identifiers = false
    return_value
  end

  def self.cached_count
    Mc.get('statz.devices_count') || 0
  end

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
    new_value = new_value ? DeviceService.normalize_mac_address(new_value) : ''
    @create_device_identifiers ||= (self.mac_address != new_value)
    put('mac_address', new_value)
  end

  def advertising_id=(new_value)
    new_value = new_value ? DeviceService.normalize_advertising_id(new_value) : ''
    put('advertising_id', new_value)
  end

  def advertising_id_device?
    return false if self.advertising_id.nil?
    self.key == self.advertising_id ||
      DeviceService.normalize_advertising_id(self.key) == self.advertising_id
  end

  def dynamic_domain_name
    domain_number = RubyVersionIndependent.hash(@key) % NUM_DEVICES_DOMAINS
    "devices_#{domain_number}"
  end

  def tjgames_registration_click_key
    "#{key}.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
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

  def last_run_app_ids
    @parsed_apps.sort_by{|k,v| v }.map{|k,v| k }.reverse
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

  def publisher_user_id_for_app(app)
    publisher_user_ids[app.id]
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
    RecommendationList.new(options.merge(:device_id => key)).apps
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

  # Clear all apps besides the most recently used
  def clear_lru_apps
    self.apps = Hash[
      self.apps.to_a.sort { |a, b| b[1] <=> a[1] }.first(APP_LIMIT) # bigger value for timestamp => used more recently
    ]
  end

  def self.formatted_mac_address(mac_address)
    mac_address.to_s.empty? ? nil : mac_address.strip.upcase.scan(/.{2}/).join(':')
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

  def set_pending_coupon(offer_id)
    self.pending_coupons += [offer_id]
    save
  end

  def remove_pending_coupon(offer_id)
    self.pending_coupons -= [offer_id]
    save
  end

  def in_network_apps
    ExternalPublisher.load_all_for_device(self).map( &:external_store_name_and_key ).compact
  end

  def mobile_carrier_code
    "#{mobile_country_code}.#{mobile_network_code}"
  end

  def set_opt_out_offer_types(opted_out_types)
    opted_in_types  = self.opt_out_offer_types - opted_out_types
    opted_out_types.each { |type| self.opt_out_offer_types = type }
    opted_in_types.each  { |type| self.delete('opt_out_offer_types', type) }
  end

  def admin_device
    @admin_device ||= AdminDevice.find_by_udid(id)
  end

  def admin_device?
    admin_device.present?
  end

  def app_ids_sorted_by_last_run_time
    parsed_apps.sort{ |a,b| b[1] <=> a[1] }.map(&:first)
  end

  private

  # Class var holding procs which attempt to find where the 'good' JSON ends
  # and return a pair of strings, the first of which is suspected to hold valid
  # JSON and the second of which is the 'leftovers', which *might* hold some valid
  # JSON but we are OK with losing it in favor of getting this attribute repaired
  @@badness_splitters = []

  # Some possibly valid JSON may exist after the token that
  # caused the parser error
  @@badness_splitters << lambda do |str, e|
    raise unless badness = e.message.match(/unexpected token at '([^']+)/)[1]
    raise unless last_good_curly_pos = str.index("}#{badness}")

    # split at first '{' and try to parse
    # the remaining json
    before = str[0 .. last_good_curly_pos]
    after  = str[last_good_curly_pos + 1 .. -1]

    [before, after]
  end

  # Last ditch effort- slice at the last comma, replace it with a },
  # and try to parse. It's possible running this proc multiple times on the same
  # string might work for every string... eventually
  @@badness_splitters << lambda do |str, e|
    last_comma_pos = str.rindex(',')

    before = str[0 .. last_comma_pos - 1] + '}'
    after  = str[last_comma_pos + 1 .. -1]

    [before, after]
  end

  def parse_bad_json_with_badness_splitters(str, e)
    @@badness_splitters.reduce({}) do |result, splitter|
      before, after = splitter.call(str, e) rescue [nil, nil]

      # we may be missing the open '{'
      after = "{#{after}" if after.present? && !after.starts_with?('{')

      data = nil
      begin
        data                = before ? JSON.parse(before) : nil
      rescue JSON::ParserError => e
        LiveDebugger.new('user_events_bad_json_error').log(before.inspect)
      end

      data_after_badness  = after  ? (JSON.parse(after) rescue {}) : {}

      # If we got some data, merge it into the result
      # It's OK to merge; we shouldn't be getting conflicting values on successive
      # passes here, but we might have some data another pass missed
      data ? result.reverse_merge(data.reverse_merge(data_after_badness)) : result
    end.tap { |data| data.empty? and raise(e) }
  end

  def parse_bad_json(attribute, search_from = :left)
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

    JSON.parse(str)
  rescue JSON::ParserError => e
    parse_bad_json_with_badness_splitters(str, e)
  end

  def fix_app_json
    begin
      @parsed_apps = apps
    rescue JSON::ParserError
      @parsed_apps = parse_bad_json('apps')
      self.put('apps', @parsed_apps, :type => :json, :cgi_escape => false, :replace => true)
    end
  end

  def fix_publisher_user_ids_json
    begin
      publisher_user_ids
    rescue JSON::ParserError
      good_data = parse_bad_json('publisher_user_ids', :right)
      self.put('publisher_user_ids', good_data, :type => :json, :cgi_escape => false, :replace => true)
    end
  end

  def fix_display_multipliers_json
    begin
      display_multipliers
    rescue JSON::ParserError
      good_data = parse_bad_json('display_multipliers', :right)
      self.put('display_multipliers', good_data, :type => :json, :cgi_escape => false, :replace => true)
    end
  end
end
