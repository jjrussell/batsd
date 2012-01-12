class OneOffs

  def self.populate_app_metadata_categories
    AppMetadata.connection.execute("UPDATE app_metadatas SET categories = NULL")
    App.find_each do |app|
      if app.app_metadatas.present? && app.read_attribute(:categories).present?
        app.app_metadatas.first.write_attribute(:categories, app.read_attribute(:categories))
        app.app_metadatas.first.save!
      end
    end
  end

end
