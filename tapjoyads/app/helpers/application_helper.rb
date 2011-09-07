# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def sdk_popup_link(text, sdk_type, show_clippy=true)
    concat(link_to(text, popup_sdk_path(:sdk => sdk_type), :rel => 'facebox'))
    if permitted_to?(:index, :statz) && show_clippy
      concat('<br/>')
      concat(clippy(sdk_path(sdk_type, :only_path => false)))
    end
  end
end
