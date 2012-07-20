class OneOffs
  def self.create_icons_by_app_metadata_ids
    app_count = 0
    icon_count = 0
    start_time = Time.now
    
    App.live.each do |app|
      puts "#{app_count}: #{app.name}"
      app_count += 1
      old_icon_id = Offer.hashed_icon_id(app.id)
      new_icon_id = Offer.hashed_icon_id(app.primary_app_metadata.id)
      bucket  = S3.bucket(BucketNames::TAPJOY)

      ['src', '256', '114', '57'].each do |path|
        origin_icon_obj = bucket.objects["icons/#{path}/#{old_icon_id}.jpg"]
        begin
          bucket.objects["icons/#{path}/#{old_icon_id}.jpg"].copy_to(AWS::S3::S3Object.new(bucket,"icons/#{path}/#{new_icon_id}.jpg",  {:acl => :public_read }))
        rescue
          puts "error: App: #{app.name}, can't find icons/#{path}/#{old_icon_id}.jpg"
        end

        if path == '57'
          begin
            bucket.objects["icons/57/#{old_icon_id}.png"].copy_to(AWS::S3::S3Object.new(bucket,"icons/57/#{new_icon_id}.png",  {:acl => :public_read }))
          rescue
            puts "error: App: #{app.name}, can't find icons/57/#{old_icon_id}.png"
          end
        end
      end
    end
    puts "total app prcessed: #{app_count}, icon copied: #{icon_count}"
    puts "Start time: #{start_time}, end time : #{Time.now}"
  end

end
