class OneOffs

  def self.fill_app_reviews
    AppReview.connection.execute 'UPDATE app_reviews SET is_blank = true WHERE text = ""'
  end

end
