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

  NO_URL = 'NO_URL'

  belongs_to :author, :polymorphic => true
  belongs_to :offer
  has_one :tracking_offer, :class_name => 'Offer', :as => :tracking_for, :conditions => 'id = tracking_for_id'

  validates_presence_of :author, :if => :author_required?, :message => "Please select an author."
  validates_presence_of :offer, :if => :offer_required?, :message => "Please select an offer/app."
  validates_presence_of :featured_type, :platforms, :subtitle, :title, :description, :start_date, :end_date, :weight

  before_save :create_offer
  after_create :create_tracking_offer
  after_update :update_tracking_offer

  named_scope :ordered_by_date, :order => "start_date DESC, end_date DESC"
  named_scope :upcoming,  lambda { |date| { :conditions => [ "start_date > ?", date.to_date ], :order => "start_date ASC" } }
  named_scope :expired,  lambda { |date| { :conditions => [ "end_date < ?", date.to_date ], :order => "end_date ASC" } }
  named_scope :active, lambda { |date| { :conditions => [ "start_date <= ? AND end_date >= ?", date.to_date, date.to_date ] } }
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platforms LIKE ?", "%#{platform}%" ] } }
  named_scope :for_featured_type, lambda { |featured_type| { :conditions => [ "featured_type = ?", featured_type ] } }

  json_set_field :platforms

  def self.featured_contents(platform)
    platform = 'iphone' unless %w(android iphone windows).include?(platform)
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

  def self.with_country_targeting(geoip_data, device, platform)
    featured_contents = FeaturedContent.featured_contents(platform)
    featured_contents.delete_if do |fc|
      !!fc.tracking_offer &&
      !!device &&
      fc.tracking_offer.geoip_reject?(geoip_data)
    end
  end

  def get_icon_url(icon_id, options = {})
    icon_obj = S3.bucket(BucketNames::TAPJOY).objects["icons/src/#{icon_id}.jpg"]

    return FeaturedContent.get_icon_url({:icon_id => icon_id}.merge(options)) if icon_obj.exists?
    return main_icon_url if icon_id == "#{id}_main" and main_icon_url.present?
    return secondary_icon_url if icon_id == "#{id}_secondary" and secondary_icon_url.present?
    return get_default_icon_url
  end

  def self.get_icon_url(options = {})
    source     = options.delete(:source)   { :cloudfront }
    icon_id    = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL

    "#{prefix}/icons/src/#{icon_id}.jpg"
  end

  def get_default_icon_url(options = {})
    FeaturedContent.get_icon_url({ :icon_id => 'dynamic_staff_pick_tool', :source => :cloudfront }.merge(options))
  end

  def save_icon!(icon_src_blob, icon_id)
    bucket  = S3.bucket(BucketNames::TAPJOY)
    src_obj = bucket.objects["icons/src/#{icon_id}.jpg"]
    existing_icon_blob = src_obj.exists? ? src_obj.read : ''

    return if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)

    src_obj.write(:data => icon_src_blob, :acl => :public_read)

    Mc.delete("icon.s3.#{id}")
  end

  def expired?
    end_date < Time.zone.now.to_date
  end

  def expire!
    self.end_date = Time.zone.now - 2.days
    save!
  end

  def has_valid_url?
    button_url != NO_URL
  end

  private

  def author_required?
    [ TYPES_MAP[STAFFPICK], TYPES_MAP[NEWS], TYPES_MAP[CONTEST] ].include?(featured_type)
  end

  def offer_required?
    [ TYPES_MAP[STAFFPICK], TYPES_MAP[PROMO] ].include?(featured_type)
  end

  def create_offer
    unless offer
      item = GenericOffer.create(
        :name       => "For_Featured_Content_#{id}",
        :url        => NO_URL,
        :partner_id => TAPJOY_PARTNER_ID
      )
      self.offer      = item.primary_offer
      self.button_url = NO_URL
    end
  end

  def create_tracking_offer
    if offer && !tracking_offer
      if offer.item_type == 'App'
        self.tracking_offer = offer.item.create_tracking_offer_for(self,
          :device_types => platforms,
          :url_overridden => true,
          :url => button_url
        )
      else
        self.tracking_offer = offer.item.create_tracking_offer_for(self, :device_types => platforms)
      end
      save
    end
  end

  def update_tracking_offer
    if tracking_offer
      if offer
        self.tracking_offer.device_types = platforms if platforms_changed?
        self.tracking_offer.save! if self.tracking_offer.changed?
      end
    else
      create_tracking_offer
    end
  end
end
