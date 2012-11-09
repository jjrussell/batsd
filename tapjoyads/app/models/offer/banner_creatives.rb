module Offer::BannerCreatives

  def self.included(base)
    base.class_eval do
      serialize :banner_creatives, Array
      serialize :approved_banner_creatives, Array
      serialize :creatives_dict, Hash

      const_set(:DISPLAY_AD_SIZES, ['320x50', '640x100', '768x90']) # data stored as pngs

      const_set(:FEATURED_AD_LEGACY_SIZES, ['960x640', '640x960', '480x320', '320x480']) # data stored as jpegs
      const_set(:FEATURED_AD_LANDSCAPE_SIZES, ['300x250', '1000x490'])
      const_set(:FEATURED_AD_PORTRAIT_SIZES, ['300x250', '748x720'])
      const_set(:FEATURED_AD_SIZES, (Offer::FEATURED_AD_PORTRAIT_SIZES + Offer::FEATURED_AD_LANDSCAPE_SIZES).uniq) # data stored as jpegs

      # To support legacy featured ad custom creatives, we need some additional categories to check
      const_set(:FEATURED_AD_ALL_SIZES, Offer::FEATURED_AD_SIZES + Offer::FEATURED_AD_LEGACY_SIZES)
      const_set(:FEATURED_AD_PREVIEW_SIZES, ['960x640', '640x960', '480x320', '320x480'])

      const_set(:ALL_CUSTOM_AD_SIZES, Offer::DISPLAY_AD_SIZES + Offer::FEATURED_AD_ALL_SIZES)

      Offer::ALL_CUSTOM_AD_SIZES.each do |size|
        attr_accessor "banner_creative_#{size}_blob".to_sym
      end
    end
  end

  %w(banner_creatives approved_banner_creatives).each do |method_name|
    class_eval <<-EOS
      def #{method_name}
        self.send("#{method_name}=", []) if super.nil?
        super.sort
      end

      def #{method_name}_was
        super || []
      end
    EOS
  end

  def creatives_dict
    super || {}
  end

  def can_change_banner_creatives?
    !rewarded? || featured?
  end

  def banner_creative_sizes(return_all = false, return_depricated = false)
    return Offer::ALL_CUSTOM_AD_SIZES if return_all
    return Offer::DISPLAY_AD_SIZES unless featured?
    return Offer::FEATURED_AD_SIZES unless return_depricated
    return Offer::FEATURED_AD_ALL_SIZES
  end

  def banner_creative_sizes_with_labels
    banner_creative_sizes(false, true).collect do |size|

      data = {:size => size, :label => size.dup, :desc => ''}

      if featured? && Offer::FEATURED_AD_SIZES.include?(size) # only apply for 2012 new featured ad
        if (Offer::FEATURED_AD_LANDSCAPE_SIZES.include?(size) && Offer::FEATURED_AD_PORTRAIT_SIZES.include?(size))
          orientation = 'landscape/portrait'
        elsif Offer::FEATURED_AD_LANDSCAPE_SIZES.include?(size)
          orientation = 'landscape'
        else
          orientation = 'portrait'
        end

        w,h = size.split('x')
        device = w.to_i > 500 ? 'tablet' : 'phone'

        data[:desc] << "#{device} #{orientation}"
      end

      data
    end
  end

  def featured_ad_preview_sizes_with_labels
    @featured_ad_preview_sizes_with_labels ||= Offer::FEATURED_AD_PREVIEW_SIZES.map{ |s|
      w,h = s.split('x')
      {:label => "#{s} #{w.to_i > 500 ? 'tablet' : 'phone'} #{w < h ? 'portrait' : 'landscape'}", :size => s}
    }
  end

  def should_update_approved_banner_creatives?
    banner_creatives_changed? && banner_creatives != approved_banner_creatives
  end

  def banner_creatives_changed?
    return false if (super && banner_creatives_was.empty? && banner_creatives.empty?)
    super
  end

  def has_banner_creative?(size)
    self.banner_creatives.include?(size)
  end

  def banner_creative_approved?(size)
    has_banner_creative?(size) && self.approved_banner_creatives.include?(size)
  end

  def remove_banner_creative(size)
    return unless has_banner_creative?(size)
    self.banner_creatives = banner_creatives.reject { |c| c == size }
    self.approved_banner_creatives = approved_banner_creatives.reject { |c| c == size }
  end

  def add_banner_creative(image_data, size)
    return unless banner_creative_sizes(true).include?(size)
    self.banner_creatives += [size] unless has_banner_creative?(size)
    send("banner_creative_#{size}_blob=", image_data)
    set_primary_key if new_record? # we use "id" below, so we need to be sure it's set
    self.creatives_dict = creatives_dict.merge(size => "#{IconHandler.hashed_icon_id(self.id)}_#{Time.now.to_i.to_s}_#{size}")
  end

  def approve_banner_creative(size)
    return unless has_banner_creative?(size)
    return if banner_creative_approved?(size)
    self.approved_banner_creatives += [size]
  end

  def add_banner_approval(user, size)
    approvals.create(:user => user, :size => size)
    approvals.last
  end

  def banner_creative_format(size)
    return 'jpeg' if Offer::FEATURED_AD_ALL_SIZES.include? size
    'png'
  end

  def banner_creative_path(size, format = nil)
    format ||= banner_creative_format(size)
    creatives_dict.include?(size) ? "banner_creatives/#{creatives_dict[size]}.#{format}" : "banner_creatives/#{IconHandler.hashed_icon_id(id)}_#{size}.#{format}"
  end

  def banner_creative_url(options)
    use_cloudfront = options.fetch(:use_cloudfront, true)

    base = use_cloudfront ? CLOUDFRONT_URL : "https://s3.amazonaws.com/#{BucketNames::TAPJOY}"

    url = "#{base}/#{banner_creative_path(options[:size], options[:format])}"
    url << "?" << { :ts => Time.now.to_i }.to_query if options[:bust_cache]
    url
  end

  def banner_creative_s3_object(size, format = nil)
    format ||= banner_creative_format(size)
    bucket = S3.bucket(BucketNames::TAPJOY)
    bucket.objects[banner_creative_path(size, format)]
  end

  def banner_creative_mc_key(size, format = nil)
    format ||= banner_creative_format(size)
    banner_creative_path(size, format).gsub('/', '.')
  end

  def display_custom_banner_for_size?(size)
    display_banner_ads? && banner_creative_approved?(size)
  end

  def display_banner_ads?
    return false if (is_paid? || featured?)
    return (item_type == 'App' && name.length <= 30) if rewarded?
    item_type != 'VideoOffer'
  end

  def featured_custom_creative?
    # featured custom creatives are the "old" style legacy fullscreen custom creatives.
    banner_creatives.any? { |size| Offer::ALL_CUSTOM_AD_SIZES.include?(size) }
  end

  private

  def nullify_banner_creatives
    write_attribute(:banner_creatives, nil) if banner_creatives.empty?
    write_attribute(:approved_banner_creatives, nil) if approved_banner_creatives.empty?
  end

  # keep a record of creatives that have already been uploaded during the save process
  # this helps with transactional integrity
  def uploaded_banner_creatives
    return @uploaded_banner_creatives unless @uploaded_banner_creatives.nil?
    @uploaded_banner_creatives = {}
    Offer::ALL_CUSTOM_AD_SIZES.each { |size| @uploaded_banner_creatives[size] = [] }
    @uploaded_banner_creatives
  end

  def sync_creative_approval
    # Handle banners on this end
    banner_creatives.each do |size|
      approval = approvals.find_by_size(size)

      if banner_creative_approved?(size) && approval.present?
        approvals.destroy(approval)
      elsif approval.nil?
        # In case of a desync between the queue and actual approvals
        approve_banner_creative(size)
      end
    end

    # Now remove any approval objects that are no longer valid
    approvals.each { |a| approvals.destroy(a) unless has_banner_creative?(a.size) }

    # Remove out-of-sync approvals for banners that have been removed
    self.approved_banner_creatives = self.approved_banner_creatives.select { |size| has_banner_creative?(size) }
  end

  def sync_banner_creatives!
    # How this should work...
    #
    # ONE OF:
    #
    # adding new creative(s):
    # offer.banner_creatives += ["320x50", "640x100"]
    # offer.banner_creative_320x50_blob = image_data
    # offer.banner_creative_640x100_blob = image_data
    # offer.save!
    #
    # removing creative: (only one at a time allowed)
    # offer.banner_creatives -= ["320x50"]
    # offer.save!
    #
    # updating creative: (only one at a time allowed)
    # offer.banner_creative_320x50_blob = image_data
    # offer.save!
    #
    creative_blobs = {}

    banner_creative_sizes(true).each do |size|
      image_data = send("banner_creative_#{size}_blob")
      if !image_data.blank? && !uploaded_banner_creatives[size].include?(image_data)
        creative_blobs[size] = image_data
      end
    end

    return if (!banner_creatives_changed? && creative_blobs.empty?)

    new_creatives = banner_creatives - banner_creatives_was
    removed_creatives = banner_creatives_was - banner_creatives
    changed_creatives = creative_blobs.keys - new_creatives

    if new_creatives.any?
      raise "Unable to delete or update creatives while also adding creatives" if (removed_creatives.any? || changed_creatives.any?)
    elsif (banner_creatives.size - banner_creatives_was.size).abs > 1 || creative_blobs.size > 1
      raise "Unable to delete or update more than one banner creative at a time"
    end

    error_added = false
    new_creatives.each do |new_size|
      unless creative_blobs.has_key?(new_size)
        self.errors.add("custom_creative_#{new_size}_blob".to_sym, "#{new_size} custom creative file not provided.")
        error_added = true
        next
      end
      blob = creative_blobs[new_size]
      # upload to S3
      upload_banner_creative!(blob, new_size)
    end
    raise BannerSyncError.new("multiple new file upload errors") if error_added

    removed_creatives.each do |removed_size|
      # delete from S3
      delete_banner_creative!(removed_size)
    end

    changed_creatives.each do |changed_size|
      blob = creative_blobs[changed_size]
      # upload file to S3
      upload_banner_creative!(blob, changed_size)
    end
  end

  # this is called just before caching the offer (after_commit)
  def clear_creative_blobs
    Offer::ALL_CUSTOM_AD_SIZES.each do |size|
      blob = send("banner_creative_#{size}_blob")
      blob.replace("") if blob
    end
    @uploaded_banner_creatives = nil
  end

  def delete_banner_creative!(size, format = nil)
    format ||= banner_creative_format(size)
    banner_creative_s3_object(size, format).delete
  rescue
    raise BannerSyncError.new("Encountered unexpected error while deleting existing file, please try again.", "custom_creative_#{size}_blob")
  end

  # upload still updates all of the old columns, as well as populates the new one.
  def upload_banner_creative!(blob, size, format = nil)
    format ||= banner_creative_format(size)
    begin
      creative_arr = Magick::Image.from_blob(blob)
      if creative_arr.size != 1
        raise "image contains multiple layers (e.g. animated .gif)"
      end

      creative = creative_arr[0]
      creative.format = format
      creative.interlace = Magick::JPEGInterlace if format == 'jpeg'
    rescue
      raise BannerSyncError.new("New file is invalid - unable to convert to .#{format}.", "custom_creative_#{size}_blob")
    end

    width, height = size.split("x").collect{ |x| x.to_i }
    raise BannerSyncError.new("New file has invalid dimensions.", "custom_creative_#{size}_blob") if [width, height] != [creative.columns, creative.rows]

    begin
      banner_creative_s3_object(size, format).write(:data => creative.to_blob { self.quality = 85 }, :acl => :public_read)
    rescue
      raise BannerSyncError.new("Encountered unexpected error while uploading new file, please try again.", "custom_creative_#{size}_blob")
    end

    uploaded_banner_creatives[size] << blob

    # Add to memcache
    begin
      Mc.put(banner_creative_mc_key(size, format), Base64.encode64(creative.to_blob).gsub("\n", ''))
    rescue
      # no worries, it will get cached later if needed
    end

    CloudFront.invalidate(id, banner_creative_path(size, format))
  end

  class BannerSyncError < StandardError
    attr_accessor :offer_attr_name
    def initialize(message, offer_attr_name = nil)
      super(message)
      self.offer_attr_name = offer_attr_name
    end
  end
end
