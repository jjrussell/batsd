class ExternalPublisher

  attr_accessor :app_id, :app_name, :partner_name, :currencies, :last_run_time, :active_gamer_count,
                :app_metadata_id, :app_metadata, :store_url, :primary_category, :icon_url

  def initialize(currency)
    self.app_id = currency.app_id
    self.app_name = currency.app.name
    self.partner_name = currency.app.primary_app_metadata.try(:developer)
    self.partner_name = currency.app.partner_name if partner_name.blank?
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
    icon_id = (app_metadata_id ? app_metadata_id : app_id)
    IconHandler.get_icon_url(options.merge(:icon_id => IconHandler.hashed_icon_id(icon_id)))
  end

  def get_offerwall_url(device, currency, accept_language_str, user_agent_str, gamer_id = nil, no_log = false)
    language_code = I18n.locale.to_s
    device_type = HeaderParser.device_type(user_agent_str)
    os_version = HeaderParser.os_version(user_agent_str) if device_type.present?

    publisher_user_id = device.publisher_user_ids[app_id] || device.key
    display_multiplier = device.display_multipliers[app_id].present? ? device.display_multipliers[app_id] : 1

    data = {
      :udid                => device.key,
      :publisher_user_id   => publisher_user_id,
      :currency_id         => currency[:id],
      :app_id              => app_id,
      :source              => 'tj_games',
      :json                => '1',
      :display_multiplier  => "#{display_multiplier}"
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

  def self.first_rewardable_currency_for_device(device)
    external_publishers = self.load_all
    external_publishers.reject! do |app_id,external_publisher|
      !device.has_app?( app_id )
    end
    ext_pub_app_ids = external_publishers.map(&:first)
    first_rewardable = nil
    device.last_run_app_ids.detect do |app_id|
      ext_pub_app_ids.include?(app_id) and
      c = App.find( app_id ) and
      first_rewardable = c.rewardable_currencies.first
    end
    Currency.find(first_rewardable.id)
  end

  def self.load_all_for_device(device)
    external_publishers = []
    self.load_all.each do |app_id, external_publisher|
      next unless device.has_app?(app_id)
      #next unless device.publisher_user_ids[app_id].present? || external_publisher.currencies.all? { |h| h[:udid_for_user_id] }

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
    store_in_s3(external_publishers, :marshal, 'external_publishers')

    # Store metadata for Hurricane external_app
    app_metadata_ids = external_publishers.each_value.map(&:app_metadata_id).uniq.compact
    metadata_hash = {}
    AppMetadata.where(:id => app_metadata_ids).each do |app_metadata|
      metadata_hash[app_metadata.id] = app_metadata
    end

    external_publishers.each_value do |publisher|
      next unless publisher.app_metadata_id
      app_metadata           = metadata_hash[publisher.app_metadata_id]
      publisher.app_metadata = app_metadata.attributes
      publisher.app_metadata["screenshots"] = app_metadata.get_screenshots_urls

      # Converts Time data to int bc MessagePack can't pack Time
      publisher.app_metadata.slice("updated_at", "created_at", "released_at").each do |attr, val|
        publisher.app_metadata[attr] = val.to_i
      end

      publisher.store_url        = app_metadata.store_url
      publisher.primary_category = app_metadata.primary_category
      publisher.icon_url         = publisher.get_icon_url
    end
    store_in_s3(external_publishers.to_json, :message_pack, 'external_apps')

    Mc.distributed_put('external_publishers', external_publishers, false, 1.day)
  end

  def self.store_in_s3(collection, format, key)
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    case format
      when :marshal
        bucket.objects[key].write(Marshal.dump(collection))
      when :message_pack
        bucket.objects[key].write(MessagePack.pack(collection), :acl => :authenticated_read)
    end
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

  def self.find_by_app_id(app_id)
    self.load_all[app_id]
  end
end
