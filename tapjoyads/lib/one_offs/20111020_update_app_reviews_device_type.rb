class OneOffs

  def self.update_app_reviews_device_type
    AppReview.all.each do |app_review|
      app_review.update_attribute(:platform, app_review.app.platform)
    end
  end

end
