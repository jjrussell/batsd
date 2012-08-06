class OneOffs
  def self.update_app_meta_store_names
    AppMetadata.connection.execute("update app_metadatas set store_name =
      case store_name when 'App Store' then 'iphone.AppStore'
      when 'Market' then 'android.GooglePlay'
      when 'Google Play' then 'android.GooglePlay'
      when 'Marketplace' then 'windows.Marketplace'
      else store_name end")
    AppMetadataMapping.connection.execute("update app_metadata_mappings set is_primary = 1")
  end
end
