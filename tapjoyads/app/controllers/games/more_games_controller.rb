class Games::MoreGamesController < GamesController
  before_filter :set_show_nav_bar_quad_menu

  def editor_picks
    if using_android?
      @editors_picks = EditorsPick.cached_active('android')
    else
      @editors_picks = EditorsPick.cached_active('iphone')
    end
  end

  def recommended
  end

end
