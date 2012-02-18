class Device < SimpledbShardedResource
  self.num_domains = NUM_DEVICES_DOMAINS

  attr_reader :parsed_apps

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
  self.sdb_attr :product
  self.sdb_attr :version
  self.sdb_attr :mac_address
  self.sdb_attr :platform
  self.sdb_attr :is_papayan, :type => :bool, :default_value => false
  self.sdb_attr :all_packages, :type => :json, :default_value => []
  self.sdb_attr :current_packages, :type => :json, :default_value => []
  self.sdb_attr :sdkless_clicks, :type => :json, :default_value => {}

  def mac_address=(new_value)
    new_value = new_value ? new_value.downcase.gsub(/:/,"") : ''
    @create_device_identifiers ||= (self.mac_address != new_value)
    put('mac_address', new_value)
  end

  def initialize(options = {})
    super({ :load_from_memcache => true }.merge(options))
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_DEVICES_DOMAINS
    "devices_#{domain_number}"
  end

  def after_initialize
    @create_device_identifiers = is_new
    @retry_save_on_fail = is_new
    begin
      @parsed_apps = apps
    rescue JSON::ParserError
      fix_parser_error
    end
  end

  def handle_connect!(app_id, params)
    return [] unless app_id =~ APP_ID_FOR_DEVICES_REGEX

    now = Time.zone.now
    path_list = []

    self.mac_address = params[:mac_address] if params[:mac_address].present?

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

    if (last_run_time_tester? || is_jailbroken_was != is_jailbroken || country_was != country || path_list.include?('daily_user'))
      save
    end

    path_list
  end

  def set_last_run_time(app_id)
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

  def self.normalize_device_type(device_type_param)
    if device_type_param =~ /iphone/i
      'iphone'
    elsif device_type_param =~ /ipod/i
      'itouch'
    elsif device_type_param =~ /ipad/i
      'ipad'
    elsif device_type_param =~ /itouch/i
      'itouch'
    elsif device_type_param =~ /android/i
      'android'
    elsif device_type_param =~ /windows/i
      'windows'
    else
      nil
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
    Gamer.find(:all, :joins => [:gamer_devices], :conditions => ['gamer_devices.device_id = ?', key])
  end

  def update_package_names!(package_names)
    return if ((package_names - current_packages) | (current_packages - package_names)).empty?
    self.all_packages |= package_names
    self.current_packages = package_names
    save!
  end

  def serial_save(options = {})
    return_value = super({ :write_to_memcache => true }.merge(options))
    Sqs.send_message(QueueNames::CREATE_DEVICE_IDENTIFIERS, {'device_id' => key}.to_json) if @create_device_identifiers
    @create_device_identifiers = false
    return_value
  end

  def create_identifiers!
    all_identifiers = [ Digest::SHA2.hexdigest(key) ]
    all_identifiers.push(mac_address) if self.mac_address.present?
    all_identifiers.each do |identifier|
      device_identifier = DeviceIdentifier.new(:key => identifier)
      next if device_identifier.udid == key
      device_identifier.udid = key
      device_identifier.save!
    end
  end

  def handle_sdkless_click!(offer, now)
    if offer.sdkless?
      temp_sdkless_clicks = sdkless_clicks
      temp_sdkless_clicks[offer.third_party_data] = { 'click_time' => now.to_i, 'item_id' => offer.item_id }
      temp_sdkless_clicks.reject! { |key, value| value['click_time'] <= (now - 2.days).to_i }
      self.sdkless_clicks = temp_sdkless_clicks
      @retry_save_on_fail = true
      save
    end
  end

  private

  def fix_parser_error
    str = get('apps')
    pos = str.index('}')
    if pos.nil?
      pos = str.rindex(',')
      removed = str.slice!(pos..-1)
      str += '}'
    else
      removed = str.slice!(pos+1..-1)
    end
    @parsed_apps = JSON.parse(str)
    self.apps = @parsed_apps
  end

end
