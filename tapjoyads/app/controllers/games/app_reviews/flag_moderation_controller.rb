require 'games/app_reviews/moderation_module'

class Games::AppReviews::FlagModerationController < GamesController
  before_filter :require_gamer

  include Games::AppReviews::ModerationModule

  private
  def post_params
    params.slice( *([:app_review_id]) )
  end
  def verb
    t("text.games.app_review_concern_reported") #'Concern reported'
  end
  def current_gamer_votes
    current_gamer.bury_review_votes
  end
  def yes_class
    "concern"
  end
end
