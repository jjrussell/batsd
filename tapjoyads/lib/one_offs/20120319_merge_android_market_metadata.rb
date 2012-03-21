class OneOffs
  def self.merge_android_market_metadata
    counter = apps_updated = 0
    AppMetadata.find_each( :conditions => {:store_name => 'Market'} ) do |app_metadata|
      if new_metadata = AppMetadata.find_by_store_name_and_store_id('Google Play', app_metadata.store_id)
        puts "Processing app metadata #{app_metadata.store_id}, with #{app_metadata.apps.count} apps..."
        app_metadata.apps.each do |app|
          apps_updated += 1
          app.app_metadatas.delete(app_metadata)
          app.add_app_metadata(new_metadata)
          app.save!
        end

        app_metadata.destroy
        counter += 1
      end
    end
    puts "Processed #{counter} app_metadatas.  Updated #{apps_updated} apps."

    AppMetadata.connection.execute("update app_metadatas set store_name = 'Google Play' where store_name = 'Market'")
  end
end
