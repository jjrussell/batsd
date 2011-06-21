class ExternalPublishers < S3Resource
  self.bucket_name = BucketNames::OFFER_DATA
  DEFAULT_KEY = 'external_publishers'
  attribute :currency_ids, :type => :json, :default => []
  
  def self.default
    ExternalPublishers.find(DEFAULT_KEY).currencies
  end
  
  def self.cache
    external_publishers = ExternalPublishers.find_or_initialize_by_id(DEFAULT_KEY)
    external_publishers.currency_ids = Currency.external_publishers.collect(&:id)
    external_publishers.save!
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