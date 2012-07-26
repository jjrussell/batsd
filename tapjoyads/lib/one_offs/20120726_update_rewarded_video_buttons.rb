class OneOffs
  # This updates all current video buttons and their tracking offers to ensure the rewarded data is
  # correctly set.
  def self.update_rewarded_video_buttons
    VideoButton.find_each do |button|
      button.send(:update_tracking_offer) if button.rewarded?
    end
  end
end
