class FeaturedContent < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

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

  validates_presence_of :author, :if => :author_required?, :message => "Please select and author."
  validates_presence_of :offer, :if => :offer_required?, :message => "Please select an offer/app."
  validates_presence_of :featured_type, :platforms, :subtitle, :title, :description, :start_date, :end_date, :weight

  named_scope :ordered_by_date, :order => "start_date DESC, end_date DESC"
  named_scope :upcoming,  lambda { |date| { :conditions => [ "start_date > ?", date.to_date ], :order => "start_date ASC" } }
  named_scope :expired,  lambda { |date| { :conditions => [ "end_date < ?", date.to_date ], :order => "end_date ASC" } }
  named_scope :active, lambda { |date| { :conditions => [ "start_date <= ? AND end_date >= ?", date.to_date, date.to_date ] } }
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platforms LIKE ?", "%#{platform}%" ] } }
  named_scope :for_featured_type, lambda { |featured_type| { :conditions => [ "featured_type = ?", featured_type ] } }

  json_set_field :platforms
  memoize :get_platforms

  def self.random_select(featured_contents)
    total = featured_contents.inject(0){|sum, featured_content| sum + featured_content.weight}
    percentages = featured_contents.map do |featured_content|
      (featured_content.weight/total) * 100
    end

    current = 0
    ranges = []
    percentages.each do |percentage|
      ranges << current + percentage
      current = percentage
    end

    random_number = rand(total)
    ranges.each_with_index do |range, index|
      return featured_contents[index] if random_number < range
    end
    return featured_contents[0]
  end

  def self.featured_contents(platform)
    platform = 'iphone' unless %w(android iphone).include?(platform)
    Mc.get_and_put("featured_contents.#{platform}", false, 1.day) do
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

    Mc.delete("icon.s3.#{id}") # id ==> icon_id

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
end
