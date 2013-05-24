class Airbrake::Sender
  private
  # Airbrake uses this method to get a Net::HTTP::Proxy object it can
  # use to execute its HTTP request.  So let's sneak our own object in there
  # TODO SSL (we don't use it though)
  alias_method :setup_http_connection_dashkb, :setup_http_connection

  def setup_http_connection
    return setup_http_connection_dashkb unless ENV['ASYNC'] && EM.reactor_running?
    Object.new.tap do |http|
      http.instance_variable_set(:@delegate, self)

      def http.method_missing(m, *args, &block)
        @delegate.send(m, *args, &block)
      end

      def http.post(path, data, headers)
        begin
          req = EM::HttpRequest.new("http://#{url.host}", {
            connect_timeout: http_open_timeout,
            inactivity_timeout: http_read_timeout
          }).post({
            path: path,
            body: data,
            head: headers
          })
        rescue => e
          Rails.logger.info "Error reporting exception to airbrake: #{e}"
        end

        raise 'no response from airbrake' unless (req.response_header.status.to_i > 0 rescue nil)

        # Get proper http response class for status
        klass = Net::HTTPResponse::CODE_TO_OBJ[req.response_header.status.to_s]

        # Build + return, with shim for #body since we have it already
        klass.new('1.1', req.response_header.status, req.response).tap do |response|
          response.instance_variable_set(:@body, req.response)
          def response.body; @body; end
        end
      end
    end
  end
end

Airbrake.configure do |config|
  config.api_key = 'bdf26b75f95c3ca09c91f1d8d6491327'
  config.ignore_by_filter do |exception_data|
    if exception_data[:error_class] == 'RightAws::AwsError'
      true if exception_data[:error_message] =~ /^(ServiceUnavailable|SignatureDoesNotMatch)/
    end
  end
end
