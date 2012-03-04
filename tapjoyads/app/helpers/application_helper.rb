# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def sdk_link(text, sdk_type)
    concat(link_to(text, popup_sdk_path(:sdk => sdk_type), :rel => 'facebox'))
  end

  def games_hide_login(val)
    @games_header_hide = val
  end

  def get_games_hide_login
    return @gamer_header_hide || false
  end
end
