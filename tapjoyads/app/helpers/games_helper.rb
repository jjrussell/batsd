module GamesHelper
  def social_feature_redirect_path
    return request.env['HTTP_REFERER'] if request.env['HTTP_REFERER']
    "#{WEBSITE_URL}#{edit_games_gamer_path}"
  end
end
