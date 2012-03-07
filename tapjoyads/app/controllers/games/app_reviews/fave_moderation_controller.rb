require 'games/app_reviews/moderation_module'

class Games::AppReviews::FaveModerationController < GamesController
  before_filter :require_gamer

  include Games::AppReviews::ModerationModule

  private
  def post_params
    params.slice( *([:app_review_id, :value]) )
  end
  def verb
    t("text.games.app_review_thanks_for_feedback")
  end
  def current_gamer_votes
    current_gamer.helpful_review_votes
  end
  def yes_class
    ""
  end
end
