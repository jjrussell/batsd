class IconHandler

  class << self

    def hashed_icon_id(guid)
      Digest::SHA2.hexdigest(ICON_HASH_SALT + guid)
    end

    def icon_cache_key(guid)
      "icon.s3.#{guid}"
    end

    def get_icon_url(options = {})
      source     = options.delete(:source)   { :s3 }
      icon_id    = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
      item_type  = options.delete(:item_type)
      size       = options.delete(:size)     { (item_type == 'VideoOffer' || item_type == 'TestVideoOffer') ? '200' : '57' }
      bust_cache = options.delete(:bust_cache) { false }
      raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

      prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL

      url = "#{prefix}/icons/#{size}/#{icon_id}.jpg"
      url << "?ts=#{Time.now.to_i}" if bust_cache
      url
    end

    def remove_icon!(guid, video_offer = false)
      icon_id = hashed_icon_id(guid)
      bucket  = S3.bucket(BucketNames::TAPJOY)
      src_obj = bucket.objects["icons/src/#{icon_id}.jpg"]

      src_obj.delete if src_obj.exists?

      paths = if video_offer
                ["icons/200/#{icon_id}.jpg"]
              else
                ["icons/256/#{icon_id}.jpg", "icons/114/#{icon_id}.jpg", "icons/57/#{icon_id}.jpg", "icons/57/#{icon_id}.png"]
              end

      paths.each do |path|
        obj = bucket.objects[path]
        obj.delete if obj.exists?
      end

      Mc.delete(icon_cache_key(guid))
      CloudFront.invalidate(guid, paths)
    end

    def upload_icon!(icon_src_blob, guid, video_offer = false)
      icon_id = hashed_icon_id(guid)
      bucket  = S3.bucket(BucketNames::TAPJOY)
      src_obj = bucket.objects["icons/src/#{icon_id}.jpg"]

      existing_icon_blob = src_obj.exists? ? src_obj.read : ''
      if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)
        return false
      end

      if video_offer
        paths = ["icons/200/#{icon_id}.jpg"]

        icon_200 = Magick::Image.from_blob(icon_src_blob)[0].resize(200, 125).opaque('#ffffff00', 'white')
        corner_mask_blob = bucket.objects["display/round_mask_200x125.png"].read
        corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(200, 125)
        icon_200.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
        icon_200 = icon_200.opaque('#ffffff00', 'white')
        icon_200.alpha(Magick::OpaqueAlphaChannel)

        icon_200_blob = icon_200.to_blob{|i| i.format = 'JPG'}
        bucket.objects[paths.first].write(:data => icon_200_blob, :acl => :public_read)
        src_obj.write(:data => icon_src_blob, :acl => :public_read)
      else
        paths = ["icons/256/#{icon_id}.jpg", "icons/114/#{icon_id}.jpg", "icons/57/#{icon_id}.jpg", "icons/57/#{icon_id}.png"]

        icon_256 = Magick::Image.from_blob(icon_src_blob)[0].resize(256, 256).opaque('#ffffff00', 'white')

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
      end

      Mc.delete(icon_cache_key(guid))
      CloudFront.invalidate(guid, paths) if existing_icon_blob.present?
      true
    end

  end
end
