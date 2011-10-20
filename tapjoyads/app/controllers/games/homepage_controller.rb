class Games::HomepageController < GamesController

  before_filter :require_gamer, :except => [ :tos, :privacy ]

  def index
    @device = Device.new(:key => current_device_id) if current_device_id
    @external_publishers = ExternalPublisher.load_all_for_device(@device) if @device.present?
    @featured_review = AppReview.featured_review(@device.try(:platform))
    Rails.logger.warn "\n\n{#{current_device_id}}\n\n"
    #@gamer_profile = current_gamer.gamer_profile || GamerProfile.new
  end

  def tos
  end

  def privacy
  end

private

  def require_gamer
    if current_gamer.blank?
      redirect_to games_login_path
    end
  end

end
