class OneOffs
  def self.create_icons_by_app_metadata_ids
    app_count = 0
    icon_count = 0

    App.live.each do |app|
      app_count += 1
      old_icon_id = Offer.hashed_icon_id(app.id)
      new_icon_id = Offer.hashed_icon_id(app.primary_app_metadata.id)
      bucket  = S3.bucket(BucketNames::TAPJOY)

      ['src', '256', '114', '57'].each do |path|
        origin_icon_obj = bucket.objects["icons/#{path}/#{old_icon_id}.jpg"]
        if origin_icon_obj.exists?
          origin_icon_blob = origin_icon_obj.read
          bucket.objects["icons/#{path}/#{new_icon_id}.jpg"].write(:data => origin_icon_blob, :acl => :public_read)
          icon_count += 1
        else
          puts "error: App: #{app.name}, can't find icons/#{path}/#{old_icon_id}.jpg"
        end

        if path == '57'
          origin_icon_obj = bucket.objects["icons/57/#{old_icon_id}.png"]
          if origin_icon_obj.exists?
            origin_icon_blob = origin_icon_obj.read
            bucket.objects["icons/57/#{new_icon_id}.png"].write(:data => origin_icon_blob, :acl => :public_read)
            icon_count += 1
          else
            puts "error: App: #{app.name}, can't find icons/57/#{old_icon_id}.png"
          end
        end
      end
    end
    puts "total app prcessed: #{app_count}, icon copied: #{icon_count}"
  end

end
