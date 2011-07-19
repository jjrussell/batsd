class ExternalPublisher
  
  attr_accessor :app_id, :app_name, :currencies, :last_run_time
  
  def initialize(currency)
    self.app_id = currency.app_id
    self.app_name = currency.app.name
    add_currency(currency)
  end
  
  def add_currency(currency)
    self.currencies ||= []
    self.currencies << { :id => currency.id, :name => currency.name }
  end

  def primary_currency_name
    currencies.each { |c| return c[:name] if c[:id] == app_id }
  end
  
  def get_icon_url(options = {})
    Offer.get_icon_url(options.merge(:icon_id => Offer.hashed_icon_id(app_id)))
  end
  
  def get_offerwall_url(device, currency)
    data = {
      :udid              => device.key,
      :publisher_user_id => device.key,
      :currency_id       => currency[:id],
      :app_id            => app_id,
      :source            => 'tj_games',
    }
    # TODO: add device_type and other device info, either here or at get_offers time
    
    "https://ws.tapjoyads.com/get_offers/webpage?data=#{SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)}"
  end

  def self.load_all_for_device(device)
    device_apps = device.apps
    external_publishers = []
    self.load_all.each do |app_id, external_publisher|
      next if device_apps[app_id].blank?
      
      external_publisher.last_run_time = device_apps[app_id].to_i
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
      Marshal.restore(bucket.get(key))
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
    bucket.put(key, Marshal.dump(external_publishers))
    Mc.distributed_put(key, external_publishers, false, 1.day)
  end
  
  def self.populate_potential
    now = Time.zone.now
    yesterday = now - 1.day
    date_string = yesterday.to_s(:yyyy_mm_dd)
    
    Currency.find_each(:conditions => 'potential_external_publisher = false') do |currency|
      appstats = Appstats.new(currency.app_id, :start_time => yesterday.beginning_of_day - 1.day, :end_time => now.beginning_of_day, :stat_types => ['offerwall_views', 'display_ads_requested', 'featured_offers_requested'])
      next if appstats.stats['offerwall_views'].sum + appstats.stats['display_ads_requested'].sum + appstats.stats['featured_offers_requested'].sum == 0
      
      valid_currency = true
      count = 0
      WebRequest.select(:domain_name => "web-request-#{date_string}-0", :where => "(path = 'offers' OR path = 'display_ad_requested' OR path = 'featured_offer_requested') AND app_id = '#{currency.app_id}'") do |wr|
        if wr.udid != wr.publisher_user_id
          valid_currency = false
          break
        end
        count += 1
        break if count >= 100
      end
      
      if valid_currency && count >= 100
        currency.potential_external_publisher = true
        currency.save!
      end
    end
  end
  
end
