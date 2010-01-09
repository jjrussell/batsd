# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def get_ip_address(request)
    ip_address = request.headers['X-Forwarded-For'] || request.remote_ip
    ip_address.gsub!(/,.*$/, '')
    return ip_address
  end
end
