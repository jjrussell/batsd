module TapjoyMailerHelper
  def support_request_field(name, value)
    content_tag :p do
      content_tag(:strong, "#{name.to_s.humanize}: ") +
      "#{value.present? ? value : "N/A"}"
    end
  end
end
