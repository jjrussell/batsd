class OneOffs
  def self.set_app_metadata_id_for_app_reviews
    AppReview.find_each do |ar|
      app = App.find_by_id(ar.app_id)
      ar.app_metadata_id = app.primary_app_metadata.id if app
      ar.save! if ar.changed?
    end
  end
end
