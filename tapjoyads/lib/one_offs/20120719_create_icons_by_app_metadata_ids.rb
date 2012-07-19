class OneOffs
  def self.create_icons_by_app_metadata_ids
    print "begin"
    App.live.each do |app|
      old_icon_id = Offer.hashed_icon_id(app.id)
      new_icon_id = Offer.hashed_icon_id(app.primary_app_metadata.id)
      bucket  = S3.bucket(BucketNames::TAPJOY)

      ['src', '256', '114', '57'].each do |path|
        origin_icon_obj = bucket.objects["icons/#{path}/#{old_icon_id}.jpg"]
        next if !origin_icon_obj.exists?
        origin_icon_blob = origin_icon_obj.read
        bucket.objects["icons/#{path}/#{new_icon_id}.jpg"].write(:data => origin_icon_blob, :acl => :public_read)

        if path == '57'
          origin_icon_obj = bucket.objects["icons/57/#{old_icon_id}.png"]
          next if !origin_icon_obj.exists?
          origin_icon_blob = origin_icon_obj.read
          bucket.objects["icons/57/#{new_icon_id}.png"].write(:data => origin_icon_blob, :acl => :public_read)
        end
      end
      break
    end
  end

end
