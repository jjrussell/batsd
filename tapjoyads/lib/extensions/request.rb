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
end
