module Offer::ThirdPartyTracking

  def self.included(base)
    base.class_eval do
      const_set(:TRUSTED_TRACKING_VENDORS, %w(doubleclick.net phluantmobile.net srvntrk.com))

      [:impression_tracking_urls, :click_tracking_urls, :conversion_tracking_urls].each do |f|
        serialize f, Array
        # TODO: uncomment when / if we ever try to use these urls somewhere where they could negatively affect other offers' performance
        # due to using a vendor we don't trust, a bad url, or something of that nature

        # validates_each(f) { |record, attribute, value| record.validate_third_party_tracking_urls(attribute, value) }
      end

      def self.trusted_third_party_tracking_vendors(connector = 'and')
        Offer::TRUSTED_TRACKING_VENDORS.to_sentence(:two_words_connector => " #{connector} ", :last_word_connector => ", #{connector} ")
      end

    end
  end

  %w(impression_tracking_urls click_tracking_urls conversion_tracking_urls).each do |method_name|
    define_method method_name do |*args|
      replace_macros, timestamp = args

      self.send("#{method_name}=", []) if super().nil?
      urls = super().sort

      timestamp ||= Time.zone.now.to_i.to_s
      urls = urls.collect { |url| url.gsub("[timestamp]", timestamp) } if replace_macros
      urls
    end

    define_method "#{method_name}=" do |urls|
      super(urls.to_a.select(&:present?).map(&:to_s).map(&:strip).uniq)
    end

    define_method "#{method_name}_was" do
      super || []
    end

    define_method "queue_#{method_name.sub(/urls$/, 'requests')}" do |*args|
      timestamp = args.shift
      send(method_name, true, timestamp).each do |url|
        Downloader.queue_get_with_retry(url)
      end
    end
  end

  def validate_third_party_tracking_urls(attribute, urls)
    urls.each do |url|
      uri = URI.parse(url) rescue (self.errors.add(attribute, "must all be valid urls") and return)
      unless %w(http https).include? uri.scheme
        self.errors.add(attribute, "must begin with http:// or https://") and return
      end
      unless uri.host =~ /(^|\.)(#{Offer::TRUSTED_TRACKING_VENDORS.join('|').gsub('.','\\.')})$/
        self.errors.add(attribute, "must all use a trusted vendor (#{Offer.trusted_third_party_tracking_vendors('or')})")
        return
      end
    end
  end

end
