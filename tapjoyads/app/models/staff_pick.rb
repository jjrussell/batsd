class StaffPick < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  
  OFFER_TYPES = [ 'Staff Pick', 'Tapjoy News', 'App Promo (FAAD)', 'Contest!' ]
  WEIGHTS = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]

  belongs_to :author, :polymorphic => true
  belongs_to :offer

  validates_presence_of :author, :if => :author_required?
  validates_presence_of :offer, :if => :offer_required?
  validates_presence_of :offer_type, :platforms, :subtitle, :offer_title, :description, :start_date, :end_date, :weight
  

  named_scope :ordered_by_date, :order => "start_date DESC, end_date DESC"
  named_scope :upcoming,  lambda { |date| { :conditions => [ "start_date > ?", date.to_date ], :order => "start_date ASC" } }
  named_scope :expired,  lambda { |date| { :conditions => [ "end_date < ?", date.to_date ], :order => "end_date ASC" } }
  named_scope :active, lambda { |date| { :conditions => [ "start_date <= ? AND end_date >= ?", date.to_date, date.to_date ] } }
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platforms LIKE ?", "%#{platform}%" ] } }
  # named_scope :by_device, lambda { |platform| { :conditions => ["offers.device_types LIKE ?", "%#{platform}%" ] } }
  named_scope :for_offer_type, lambda { |offer_type| { :conditions => [ "offer_type = ?", offer_type ] } }

  json_set_field :platforms
  memoize :get_platforms


  def self.random_select(staff_picks)
    # TODO: concise this part of code!!!
    total = staff_picks.inject(0){|sum, staff_pick| sum + staff_pick.weight}
    percentages = staff_picks.map do |staff_pick|
      (staff_pick.weight/total) * 100
    end

    current = 0
    ranges = []
    percentages.each do |percentage| 
      ranges << current + percentage
      current = percentage
    end

    random_number = rand(total)
    ranges.each_with_index do |range, index|
      return staff_picks[index] if random_number < range
    end
    return staff_picks[0]
  end
    
  def self.staff_picks(platform)
    platform = 'iphone' unless %w(android iphone).include?(platform)
    # do we want to stored in Memcache? if yes, what's the time interval?
    # or
    # we could store today's pick and calculate a random one when ever there's a request comming
    Mc.get_and_put("dynamic_staff_pick.#{platform}", false, 1.day) do
      now = Time.now.utc
      staff_picks =  StaffPick.active(now).for_platform(platform) ||
                StaffPick.upcoming.for_platform(platform) ||
                StaffPick.expired(now).for_platform(platform)

      if staff_picks.nil?
        raise StaffPickEmptyError.new("Platform #{platform}, Time #{now}")
      else
        # staff_pick = staff_picks[random_select(staff_picks)]
        staff_picks
      end
    end
  end

  def get_icon_url(icon_id, options = {})
    size       = options.delete(:size)     { '57' }

    Rails.logger.info("icon_id=================>>>>>#{icon_id}")
    icon_obj = S3.bucket(BucketNames::TAPJOY).objects["icons/#{size}/#{icon_id}.jpg"]
    return StaffPick.get_icon_url({:icon_id => icon_id, :size => size}.merge(options)) if icon_obj.exists?
    Rails.logger.info("main_icon_url=================>>>>>#{main_icon_url}")
    return main_icon_url if icon_id == "#{id}_main" and main_icon_url.present?
    return secondary_icon_url if icon_id == "#{id}_secondary" and secondary_icon_url.present?
    return "http://www.tapjoy.com/images/ic_launcher_96x96.png"
    # return self.get_default_icon_url
  end

  def self.get_icon_url(options = {})
    source     = options.delete(:source)   { :s3 }
    icon_id    = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
    size       = options.delete(:size)     { '57' }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL

    "#{prefix}/icons/#{size}/#{icon_id}.jpg"
  end
  
  def self.get_default_icon_url(options = {})
    icon_id = "dynamic_staff_pick_tool"
    size   = options.delete(:size)     { '57' }
    bucket  = S3.bucket(BucketNames::TAPJOY)
    icon_obj = bucket.objects["icons/src/#{icon_id}.jpg"]
    if icon_obj.exists?
      return StaffPick.get_icon_url({:icon_id => icon_id, :size => size}.merge(options))
    else
      # manually store icon_src_blob into BucketNames::TAPJOY  to "icons/src/dynamic_staff_pick_tool.jpg"
      icon_src_blob = icon_obj.read
      save_icon!(icon_src_blob, icon_id)
      return StaffPick.get_icon_url({:icon_id => icon_id, :size => size}.merge(options))
      # save_icon_with_different_size!(icon_src_blob, icon_id, bucket)
    end
 
    "http://www.tapjoy.com/images/ic_launcher_96x96.png"
  end

  def save_icon!(icon_src_blob, icon_id)
    bucket  = S3.bucket(BucketNames::TAPJOY)
    src_obj = bucket.objects["icons/src/#{icon_id}.jpg"]

    existing_icon_blob = src_obj.exists? ? src_obj.read : ''

    return if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)
    
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

  private

  def author_required?
    [ 'Staff Pick', 'Tapjoy News', 'Contest' ].include?(offer_type)
  end
  
  def offer_required?
    [ 'Staff Pick', 'App Promo (FAAD)' ].include?(offer_type)
  end
  
end
