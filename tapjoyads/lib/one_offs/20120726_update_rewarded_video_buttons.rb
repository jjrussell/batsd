class OneOffs
  def self.update_rewarded_video_buttons
    VideoButton.find_each do |button|
      button.send(:update_tracking_offer) if button.rewarded?
    end
  end
end
