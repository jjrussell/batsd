module TapjoyMailerHelper
  def support_request_field(name, value)
    "<p><b>#{name.to_s.humanize}: </b>#{value.present? ? value : "N/A"}</p>"
  end
end
