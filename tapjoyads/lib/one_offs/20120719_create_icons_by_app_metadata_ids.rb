class OneOffs
  def self.create_icons_by_app_metadata_ids
    App.live.each do |app|
      next if app.primary_offer.blank?
      metadata_id = app.primary_offer.app_metadata_id

      old_icon_id = Offer.hashed_icon_id(app.id)
      new_icon_id = Offer.hashed_icon_id(metadata_id)
      bucket  = S3.bucket(BucketNames::TAPJOY)

      ['src', '256', '114', '57'].each do |path|
        origin_icon_blob = bucket.objects["icons/#{path}/#{old_icon_id}.jpg"]
        next if !origin_icon_blob.exists?
        bucket.objects["icons/#{path}/#{new_icon_id}.jpg"].write(:data => origin_icon_blob, :acl => :public_read)

        if path == '57'
          origin_icon_blob = bucket.objects["icons/57/#{old_icon_id}.png"]
          next if !origin_icon_blob.exists?
          bucket.objects["icons/57/#{new_icon_id}.png"].write(:data => origin_icon_blob, :acl => :public_read)
        end
      end
    end
  end

end
