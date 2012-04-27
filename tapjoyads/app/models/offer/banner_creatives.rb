module Offer::BannerCreatives

  def self.included(base)
    base.class_eval do
      serialize :banner_creatives, Array
      serialize :approved_banner_creatives, Array

      const_set(:DISPLAY_AD_SIZES, ['320x50', '640x100', '768x90']) # data stored as pngs
      const_set(:FEATURED_AD_SIZES, ['960x640', '640x960', '480x320', '320x480']) # data stored as jpegs
      const_set(:ALL_CUSTOM_AD_SIZES, Offer::DISPLAY_AD_SIZES + Offer::FEATURED_AD_SIZES)

      Offer::ALL_CUSTOM_AD_SIZES.each do |size|
        attr_accessor "banner_creative_#{size}_blob".to_sym
      end
    end
  end

  %w(banner_creatives approved_banner_creatives).each do |method_name|
    define_method method_name do
      self.send("#{method_name}=", []) if super.nil?
      super.sort
    end

    define_method "#{method_name}_was" do
      super || []
    end
  end

  def can_change_banner_creatives?
    !rewarded? || featured?
  end

  def banner_creative_sizes(return_all = false)
    return Offer::ALL_CUSTOM_AD_SIZES if return_all
    return Offer::DISPLAY_AD_SIZES if !featured?
    return Offer::FEATURED_AD_SIZES
  end

  def banner_creative_sizes_with_labels
    banner_creative_sizes.collect do |size|
      data = {:size => size, :label => size.dup}

      if featured?
        width, height = size.split('x').map(&:to_i)
        orientation = (width > height) ? 'landscape' : 'portrait';
        data[:label] << " #{orientation}"
      end

      data
    end
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

  def add_banner_creative(size)
    return unless banner_creative_sizes.include?(size)
    return if has_banner_creative?(size)
    self.banner_creatives += [size]
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
    return 'jpeg' if Offer::FEATURED_AD_SIZES.include? size
    'png'
  end

  def banner_creative_path(size, format = nil)
    format ||= banner_creative_format(size)
    "banner_creatives/#{Offer.hashed_icon_id(id)}_#{size}.#{format}"
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
    banner_creatives.any? { |size| Offer::FEATURED_AD_SIZES.include?(size) }
  end

  private

  def nullify_banner_creatives
    write_attribute(:banner_creatives, nil) if banner_creatives.empty?
    write_attribute(:approved_banner_creatives, nil) if approved_banner_creatives.empty?
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
      creative_blobs[size] = image_data if !image_data.blank?
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

  def clear_creative_blobs
    Offer::ALL_CUSTOM_AD_SIZES.each do |size|
      blob = send("banner_creative_#{size}_blob")
      blob.replace("") if blob
    end
  end

  def delete_banner_creative!(size, format = nil)
    format ||= banner_creative_format(size)
    banner_creative_s3_object(size, format).delete
  rescue
    raise BannerSyncError.new("Encountered unexpected error while deleting existing file, please try again.", "custom_creative_#{size}_blob")
  end

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

    width, height = size.split("x").collect{|x|x.to_i}
    raise BannerSyncError.new("New file has invalid dimensions.", "custom_creative_#{size}_blob") if [width, height] != [creative.columns, creative.rows]

    begin
      banner_creative_s3_object(size, format).write(:data => creative.to_blob { self.quality = 85 }, :acl => :public_read)
    rescue
      raise BannerSyncError.new("Encountered unexpected error while uploading new file, please try again.", "custom_creative_#{size}_blob")
    end

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
