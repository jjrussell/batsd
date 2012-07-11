class ExternalPublisher

  attr_accessor :app_id, :app_name, :partner_name, :currencies, :last_run_time, :active_gamer_count, :app_metadata_id

  def initialize(currency)
    self.app_id = currency.app_id
    self.app_name = currency.app.name
    self.partner_name = currency.app.partner_name
    self.active_gamer_count = currency.app.active_gamer_count
    self.app_metadata_id = currency.app.primary_app_metadata.id if currency.app.primary_app_metadata
    add_currency(currency)
  end

  def add_currency(currency)
    self.currencies ||= []
    self.currencies << { :id => currency.id, :name => currency.name, :udid_for_user_id => currency.udid_for_user_id, :tapjoy_managed => currency.tapjoy_managed? }
  end

  def primary_currency_name
    currencies.each { |c| return c[:name] if c[:id] == app_id }
  end

  def get_icon_url(options = {})
    Offer.get_icon_url(options.merge(:icon_id => Offer.hashed_icon_id(app_id)))
  end

  def get_offerwall_url(device, currency, accept_language_str, user_agent_str, gamer_id = nil, no_log = false)
    language_code = I18n.locale.to_s
    device_type = HeaderParser.device_type(user_agent_str)
    os_version = HeaderParser.os_version(user_agent_str) if device_type.present?

    publisher_user_id = device.publisher_user_ids[app_id] || device.key
    publisher_multiplier = device.publisher_multiplier[app_id]

    data = {
      :udid                => device.key,
      :publisher_user_id   => publisher_user_id,
      :currency_id         => currency[:id],
      :app_id              => app_id,
      :source              => 'tj_games',
      :json                => '1',
      :display_multiplier  => "#{publisher_multiplier}"
    }
    data[:language_code]       = language_code if language_code.present?
    data[:device_type]         = device_type if device_type.present?
    data[:os_version]          = os_version if os_version.present?
    data[:gamer_id]            = gamer_id if gamer_id.present?
    data[:no_log]              = '1' if no_log

    "#{API_URL}/get_offers?data=#{ObjectEncryptor.encrypt(data)}"
  end

  def self.most_recently_run_for_gamer(gamer)
    # return value should be... [device, gamer_device, external_publisher]
    arr = [nil, nil, nil]

    latest_run_time = 0
    gamer.gamer_devices.each do |gamer_device|
      device = Device.new(:key => gamer_device.device_id)
      external_publisher = ExternalPublisher.load_all_for_device(device).first
      next unless external_publisher.present?
      latest_run_time = [latest_run_time, external_publisher.last_run_time].max
      if latest_run_time == external_publisher.last_run_time
        arr = [device, gamer_device, external_publisher]
      end
    end

    arr
  end

  def self.load_all_for_device(device)
    external_publishers = []
    self.load_all.each do |app_id, external_publisher|
      next unless device.has_app?(app_id)
      next unless device.publisher_user_ids[app_id].present? || external_publisher.currencies.all? { |h| h[:udid_for_user_id] }

      external_publisher.last_run_time = device.parsed_apps[app_id].to_i
      external_publishers << external_publisher
    end

    external_publishers.sort! do |e1, e2|
      e2.last_run_time <=> e1.last_run_time
    end
    external_publishers
  end

  def self.load_all
    key = 'external_publishers'
    Mc.distributed_get_and_put(key, false, 1.day) do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.objects[key].read)
    end
  end

  def self.cache
    external_publishers = {}
    Currency.external_publishers.each do |currency|
      if external_publishers[currency.app_id].present?
        external_publishers[currency.app_id].add_currency(currency)
      else
        external_publishers[currency.app_id] = ExternalPublisher.new(currency)
      end
    end

    key = 'external_publishers'
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    bucket.objects[key].write(Marshal.dump(external_publishers))
    Mc.distributed_put(key, external_publishers, false, 1.day)
  end

  def self.populate_potential
    start_time = (Time.zone.now - 1.day).beginning_of_day
    conditions = "(path = '[offers]' OR path LIKE '%display_ad_requested%' OR path LIKE '%featured_offer_requested%') AND day >= '#{start_time.to_s(:yyyy_mm_dd)}'"

    Currency.find_each(:conditions => 'udid_for_user_id = false') do |currency|
      appstats = Appstats.new(currency.app_id, :start_time => start_time, :stat_types => ['offerwall_views', 'display_ads_requested', 'featured_offers_requested'])
      next if appstats.stats['offerwall_views'].sum + appstats.stats['display_ads_requested'].sum + appstats.stats['featured_offers_requested'].sum < 100

      valid_currency = true
      count = 0
      VerticaCluster.query('analytics.views', :select => 'udid, publisher_user_id', :conditions => "#{conditions} AND app_id = '#{currency.app_id}'", :limit => 100).each do |wr|
        if wr[:udid] != wr[:publisher_user_id]
          valid_currency = false
          break
        end
        count += 1
      end

      if valid_currency && count >= 100
        currency.udid_for_user_id = true
        currency.save!
      end
    end
  end

end
