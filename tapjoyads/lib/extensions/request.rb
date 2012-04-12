class ActionController::Request
  def http_headers
    return @http_headers if @http_headers

    @http_headers = {}
    headers.each do |k,v|
      # we only care about keys that begin with "HTTP_" (see http://rack.rubyforge.org/doc/SPEC.html)
      unless (key = k.to_s.sub(/^HTTP_/, '')) == k.to_s
        # convert (for example) :HTTP_CONTENT_TYPE to "Content-Type"
        @http_headers[key.titleize.gsub(' ','-')] = v
      end
    end

    @http_headers
  end

  # env that will allow:
  # new_request = ActionController::Request(request.spoof_env)
  # new_request.url # will work as expected
  # new_request.http_headers # will work as expected
  #
  # This is helpful because trying to json-encode request.env fails,
  # but json-encoding request.spoof_env works fine since it removes unnecessary env vars
  def spoof_env
    return @spoof_env if @spoof_env

    @spoof_env = {}
    env.each { |k,v| @spoof_env[k] = v if k =~ /^HTTP_/ }

    @spoof_env.merge!(env.slice('HTTPS', 'SERVER_NAME', 'SERVER_ADDR', 'SERVER_PORT', 'REQUEST_URI', 'PATH_INFO', 'SCRIPT_NAME', 'QUERY_STRING'))
  end
end
