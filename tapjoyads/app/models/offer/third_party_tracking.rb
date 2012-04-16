module Offer::ThirdPartyTracking

  def self.included(base)
    base.class_eval do
      const_set(:TRUSTED_TRACKING_VENDORS, %w( phluantmobile.net ))

      serialize :impression_tracking_urls, Array
      serialize :click_tracking_urls, Array
      serialize :conversion_tracking_urls, Array

      validates_each :impression_tracking_urls do |record, attribute, value| record.validate_third_party_tracking_urls(attribute, value); end
      validates_each :click_tracking_urls do |record, attribute, value| record.validate_third_party_tracking_urls(attribute, value); end
      validates_each :conversion_tracking_urls do |record, attribute, value| record.validate_third_party_tracking_urls(attribute, value); end
    end
  end

  %w(impression_tracking_urls click_tracking_urls conversion_tracking_urls).each do |method_name|
    define_method method_name do |*args|
      replace_macros, timestamp = args

      self.send("#{method_name}=", []) if super.nil?
      urls = super.sort

      timestamp ||= Time.zone.now.to_i.to_s
      urls = urls.collect { |url| url.gsub("[timestamp]", timestamp) } if replace_macros
      urls
    end

    define_method "#{method_name}=" do |urls|
      super(urls.select { |url| url.present? })
    end

    define_method "#{method_name}_was" do
      ret_val = super
      return [] if ret_val.nil?
      ret_val
    end

    define_method "queue_#{method_name.sub(/urls$/, 'requests')}" do |*args|
      # simulate <img> pixel tag client-side web calls...
      # we lose cookie functionality, unless we implement cookie storage on our end...
      forwarded_headers = {
        'Referer' => args.shift,
        'User-Agent' => args.shift,
        'X-Do-Not-Track' => args.shift,
        'Dnt' => args.shift
      }
      timestamp = args.shift
      send(method_name, true, timestamp).each do |url|
        Downloader.queue_get_with_retry(url, { :headers => forwarded_headers })
      end
    end
  end

  def validate_third_party_tracking_urls(attribute, urls)
    urls.each do |url|
      uri = URI.parse(url) rescue (self.errors.add(attribute, "must all be valid urls") and return)
      unless uri.host =~ /(^|\.)(#{Offer::TRUSTED_TRACKING_VENDORS.join('|').gsub('.','\\.')})$/
        vendors_list = Offer::TRUSTED_TRACKING_VENDORS.to_sentence(:two_words_connector => ' or ', :last_word_connector => ', or ')
        self.errors.add(attribute, "must all use a trusted vendor (#{vendors_list})")
        return
      end
    end
  end

end
