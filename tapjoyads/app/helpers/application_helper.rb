# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def sdk_link(text, sdk_type)
    concat(link_to(text, popup_sdk_path(:sdk => sdk_type), :rel => 'facebox'))
  end
end
