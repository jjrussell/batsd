class OneOffs

  def self.populate_app_metadata_categories
    AppMetadata.connection.execute("update app_metadatas set categories = null")
    App.find_each do |app|
      if app.primary_app_metadata.present? && app.read_attribute(:categories).present?
        app.primary_app_metadata.write_attribute(:categories, app.read_attribute(:categories))
        app.primary_app_metadata.save!
      end
    end
  end

end
