module Offer::ThirdPartyTracking

  def self.included(base)
    base.class_eval do
      const_set(:TRUSTED_TRACKING_VENDORS, %w(doubleclick.net phluantmobile.net srvntrk.com))
      const_set(:TRACKING_MACROS, [:timestamp, :ip_address, :uid, :user_agent])

      [:impression_tracking_urls, :click_tracking_urls, :conversion_tracking_urls].each do |f|
        serialize f, Array
        # TODO: uncomment when / if we ever try to use these urls somewhere where they could negatively affect other offers' performance
        # due to using a vendor we don't trust, a bad url, or something of that nature

        # validates_each(f) { |record, attribute, value| record.validate_third_party_tracking_urls(attribute, value) }
      end

      def self.trusted_third_party_tracking_vendors(connector = 'and')
        Offer::TRUSTED_TRACKING_VENDORS.to_sentence(:two_words_connector => " #{connector} ", :last_word_connector => ", #{connector} ")
      end

      def self.tracking_macros(connector = 'and')
        Offer::TRACKING_MACROS.collect { |macro| "\"[#{macro}]\"" }.to_sentence(:two_words_connector => " #{connector} ", :last_word_connector => ", #{connector} ")
      end

    end
  end

  %w(impression_tracking_urls click_tracking_urls conversion_tracking_urls).each do |method_name|
    class_eval <<-EOS
    def #{method_name}(*args)
      macros = args.extract_options!
      replace_macros = args.first

      self.#{method_name} = [] unless super()
      urls = super().sort

      if replace_macros
        now = Time.zone.now
        macros[:timestamp] ||= "\#{now.to_i}.\#{now.usec}"
        Offer::TRACKING_MACROS.each do |macro|
          urls.collect! { |url| url.gsub(/\\[\#{macro}\\]/i, macros[macro].to_s) }
        end
      end
      urls
    end

    def #{method_name}=(urls)
      super(urls.to_a.select(&:present?).map(&:to_s).map(&:strip).uniq)
    end

    def #{method_name}_was
      super || []
    end

    def queue_#{method_name.sub(/urls$/, 'requests')}(*args)
      macros = args.extract_options!
      macros[:uid] = Device.advertiser_device_id(macros.delete(:udid), partner_id)
      macros[:user_agent] = source_token(macros.delete(:publisher_app_id))

      send("#{method_name}", true, macros).each do |url|
        Downloader.queue_get_with_retry(url, :offer_id => self.id, :url_type => "#{method_name}")
      end
    end
EOS
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
