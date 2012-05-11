module TapjoyMailerHelper
  def support_request_field(name, value)
    "<p><strong>#{name.to_s.humanize}: </strong>#{value.present? ? value : "N/A"}</p>"
  end
end
