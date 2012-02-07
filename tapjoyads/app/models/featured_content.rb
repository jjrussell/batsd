class FeaturedContent < ActiveRecord::Base
  include UuidPrimaryKey

  STAFFPICK = 0
  NEWS      = 1
  PROMO     = 2
  CONTEST   = 3

  TYPES_MAP = {
     STAFFPICK => 'StaffPick',
     NEWS      => 'News',
     PROMO     => 'Promo',
     CONTEST   => 'Contest'
   }

  WEIGHTS = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]

  belongs_to :author, :polymorphic => true
  belongs_to :offer
  has_one :tracking_offer, :class_name => 'Offer', :dependent => :destroy, :conditions => ['fc_tracking = ?', true]

  validates_presence_of :author, :if => :author_required?, :message => "Please select an author."
  validates_presence_of :offer, :if => :offer_required?, :message => "Please select an offer/app."
  validates_presence_of :featured_type, :platforms, :subtitle, :title, :description, :start_date, :end_date, :weight

  before_save :update_tracking_offer

  named_scope :ordered_by_date, :order => "start_date DESC, end_date DESC"
  named_scope :upcoming,  lambda { |date| { :conditions => [ "start_date > ?", date.to_date ], :order => "start_date ASC" } }
  named_scope :expired,  lambda { |date| { :conditions => [ "end_date < ?", date.to_date ], :order => "end_date ASC" } }
  named_scope :active, lambda { |date| { :conditions => [ "start_date <= ? AND end_date >= ?", date.to_date, date.to_date ] } }
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platforms LIKE ?", "%#{platform}%" ] } }
  named_scope :for_featured_type, lambda { |featured_type| { :conditions => [ "featured_type = ?", featured_type ] } }

  json_set_field :platforms

  def self.featured_contents(platform)
    platform = 'iphone' unless %w(android iphone).include?(platform)
    Mc.get_and_put("featured_contents.#{platform}", false, 1.hour) do
      now = Time.now.utc
      featured_contents =  FeaturedContent.active(now).for_platform(platform) ||
                FeaturedContent.upcoming.for_platform(platform) ||
                FeaturedContent.expired(now).for_platform(platform)

      if featured_contents.nil?
        raise FeaturedContentEmptyError.new("Platform #{platform}, Time #{now}")
      else
        featured_contents
      end
    end
  end

  def self.with_country_targeting(geoip_data, device)
    featured_contents = FeaturedContent.featured_contents(device.try(:platform))
    featured_contents.delete_if do |fc|
      !!fc.tracking_offer &&
      !!device &&
      fc.tracking_offer.geoip_reject?(geoip_data, device)
    end
  end

  def get_icon_url(icon_id, options = {})
    size     = options.delete(:size)     { '57' }
    icon_obj = S3.bucket(BucketNames::TAPJOY).objects["icons/#{size}/#{icon_id}.jpg"]

    return FeaturedContent.get_icon_url({:icon_id => icon_id, :size => size}.merge(options)) if icon_obj.exists?
    return main_icon_url if icon_id == "#{id}_main" and main_icon_url.present?
    return secondary_icon_url if icon_id == "#{id}_secondary" and secondary_icon_url.present?
    return get_default_icon_url
  end

  def self.get_icon_url(options = {})
    source     = options.delete(:source)   { :s3 }
    icon_id    = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
    size       = options.delete(:size)     { '57' }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL

    "#{prefix}/icons/#{size}/#{icon_id}.jpg"
  end

  def get_default_icon_url(options = {})
    icon_id = "dynamic_staff_pick_tool"
    size   = options.delete(:size)     { '57' }
    bucket  = S3.bucket(BucketNames::TAPJOY)
    icon_obj = bucket.objects["icons/#{size}/#{icon_id}.jpg"]
    if icon_obj.exists?
      return FeaturedContent.get_icon_url({:icon_id => icon_id, :size => size}.merge(options))
    else
      icon_src_blob = bucket.objects["icons/src/#{icon_id}.jpg"].read
      save_icon_in_different_sizes!(icon_src_blob, icon_id, bucket)
      return FeaturedContent.get_icon_url({:icon_id => icon_id, :size => size}.merge(options))
    end
  end

  def save_icon!(icon_src_blob, icon_id)
    bucket  = S3.bucket(BucketNames::TAPJOY)
    src_obj = bucket.objects["icons/src/#{icon_id}.jpg"]
    existing_icon_blob = src_obj.exists? ? src_obj.read : ''

    return if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)

    save_icon_in_different_sizes!(icon_src_blob, icon_id, bucket)
    src_obj.write(:data => icon_src_blob, :acl => :public_read)

    Mc.delete("icon.s3.#{id}")

    # Invalidate cloudfront
    if existing_icon_blob.present?
      begin
        acf = RightAws::AcfInterface.new
        acf.invalidate('E1MG6JDV6GH0F2', ["/icons/256/#{icon_id}.jpg", "/icons/114/#{icon_id}.jpg", "/icons/57/#{icon_id}.jpg", "/icons/57/#{icon_id}.png"], "#{id}.#{Time.now.to_i}")
      rescue Exception => e
        Notifier.alert_new_relic(FailedToInvalidateCloudfront, e.message)
      end
    end
  end

  def tracking_url(options = {})
    geoip_data         = options.delete(:geoip_data)         { |k| raise "#{k} is a required argument" }
    device             = options.delete(:device)             { |k| raise "#{k} is a required argument" }
    device_name        = options.delete(:device_name)        { |k| raise "#{k} is a required argument" }
    gamer_id           = options.delete(:gamer_id)           { nil }
    language_code      = options.delete(:language_code)      { nil }
    display_multiplier = options.delete(:display_multiplier) { nil }
    library_version    = options.delete(:library_version)    { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    currency = Currency.find(:first)

    click_url = tracking_offer.click_url(
      :publisher_app      => tracking_offer.item,
      :publisher_user_id  => "",
      :udid               => device.id,
      :currency_id        => currency.id,
      :source             => 'tj_games',
      :app_version        => "",
      :viewed_at          => Time.zone.now,
      :exp                => "",
      :country_code       => geoip_data[:country],
      :language_code      => language_code,
      :display_multiplier => display_multiplier,
      :device_name        => device_name,
      :library_version    => library_version,
      :gamer_id           => gamer_id)

    if tracking_offer.item_type == 'VideoOffer' || tracking_offer.item_type == 'TestVideoOffer'
      if tracking_offer.item.platform == 'windows'
        prefix = "http://tjvideo.tjvideo.com/tjvideo?"
      else
        prefix = "tjvideo://"
      end
      params = {
        :video_id => offer.id,
        :amount => currency.get_visual_reward_amount(offer, display_multiplier),
        :currency_name => currency.name,
        :click_url => click_url
      }
      "#{prefix}#{params.to_query}"
    else
      click_url
    end
  end

  private

  def save_icon_in_different_sizes!(icon_src_blob, icon_id, bucket)
    icon_256 = Magick::Image.from_blob(icon_src_blob)[0].resize(256, 256).opaque('#ffffff00', 'white')
    icon_obj = S3.bucket(BucketNames::TAPJOY).objects[icon_id]

    corner_mask_blob = bucket.objects["display/round_mask.png"].read
    corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(256, 256)
    icon_256.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
    icon_256 = icon_256.opaque('#ffffff00', 'white')
    icon_256.alpha(Magick::OpaqueAlphaChannel)

    icon_256_blob = icon_256.to_blob{|i| i.format = 'JPG'}
    icon_114_blob = icon_256.resize(114, 114).to_blob{|i| i.format = 'JPG'}
    icon_57_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'JPG'}
    icon_57_png_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'PNG'}

    bucket.objects["icons/256/#{icon_id}.jpg"].write(:data => icon_256_blob, :acl => :public_read)
    bucket.objects["icons/114/#{icon_id}.jpg"].write(:data => icon_114_blob, :acl => :public_read)
    bucket.objects["icons/57/#{icon_id}.jpg"].write(:data => icon_57_blob, :acl => :public_read)
    bucket.objects["icons/57/#{icon_id}.png"].write(:data => icon_57_png_blob, :acl => :public_read)
  end

  def author_required?
    [ TYPES_MAP[STAFFPICK], TYPES_MAP[NEWS], TYPES_MAP[CONTEST] ].include?(featured_type)
  end

  def offer_required?
    [ TYPES_MAP[STAFFPICK], TYPES_MAP[PROMO] ].include?(featured_type)
  end

  def create_tracking_offer
    if button_url.present?
      item = GenericOffer.find_by_id(FEATURED_CONTENT_GENERIC_TRACKING_OFFER_ID)

      self.tracking_offer = Offer.create!({
        :item             => item,
        :partner          => Partner.find_by_id(TAPJOY_PARTNER_ID),
        :name             => "#{title}_#{subtitle}",
        :url_overridden   => true,
        :url              => button_url,
        :device_types     => platforms,
        :price            => 0,
        :bid              => 0,
        :min_bid_override => 0,
        :rewarded         => false,
        :name_suffix      => 'fc_tracking',
        :third_party_data => id,
        :fc_tracking      => true
      })
    end
  end

  def update_tracking_offer
    if button_url.present?
      if tracking_offer
        self.tracking_offer.name         = "#{title}_#{subtitle}" if title_changed? || subtitle_changed?
        self.tracking_offer.url          = button_url if button_url_changed?
        self.tracking_offer.device_types = platforms.to_json if platforms_changed?
        self.tracking_offer.save! if self.tracking_offer.changed?
      else
        create_tracking_offer
      end
    end
  end
end
