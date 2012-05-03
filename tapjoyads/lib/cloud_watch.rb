# This is heavily borrowed from the amazon-ec2 gem
# https://github.com/grempe/amazon-ec2
class CloudWatch

  ENDPOINT = 'monitoring.amazonaws.com'

  class << self
    def put_metric_data(namespace, metrics)
      params = {'Namespace' => namespace}
      metrics.each do |metric|
        metric.each do |name,value|
          params["MetricData.member.#{metrics.index(metric) + 1}.#{name}"] = value.to_s
        end
      end

      return response_generator(:action => 'PutMetricData', :params => params)
    end

    private

    # allow us to have a one line call in each method which will do all of the work
    # in making the actual request to AWS.
    def response_generator( options = {} )

      options = {
        :action => "",
        :params => {}
      }.merge(options)

      http_response = make_request(options[:action], options[:params])

      return http_response
    end

    # Make the connection to AWS passing in our request.
    def make_request(action, params, data='')

      # remove any keys that have nil or empty values
      params.reject! { |key, value| value.nil? || value.empty? }

      params.merge!( {"Action" => action,
                      "SignatureVersion" => "2",
                      "SignatureMethod" => 'HmacSHA256',
                      "AWSAccessKeyId" => ENV['AWS_ACCESS_KEY_ID'],
                      "Version" => '2010-08-01',
                      "Timestamp"=>Time.now.getutc.iso8601} )

      sig = get_aws_auth_param(params, ENV['AWS_SECRET_ACCESS_KEY'], ENDPOINT)

      query = params.sort.collect do |param|
        CGI::escape(param[0]) + "=" + CGI::escape(param[1])
      end.join("&") + "&Signature=" + sig

      headers = {'User-Agent' => 'Tapjoy Operations'}

      sess = Patron::Session.new
      sess.timeout = 2

      url = "https://#{ENDPOINT}/?#{query}"
      response = sess.get(url, headers)

      return response
    end

    # Set the Authorization header using AWS signed header authentication
    def get_aws_auth_param(params, secret_access_key, server)
      canonical_string  = canonical_string(params, server, 'GET', '/')
      encoded_canonical = encode(secret_access_key, canonical_string)
    end

    # Builds the canonical string for signing requests. This strips out all '&', '?', and '='
    # from the query string to be signed.  The parameters in the path passed in must already
    # be sorted in case-insensitive alphabetical order and must not be url encoded.
    #
    # @param [String] params the params that will be sorted and encoded as a canonical string.
    # @param [String] host the hostname of the API endpoint.
    # @param [String] method the HTTP method that will be used to submit the params.
    # @param [String] base the URI path that this information will be submitted to.
    # @return [String] the canonical request description string.
    def canonical_string(params, host, method="GET", base="/")
      # Sort, and encode parameters into a canonical string.
      sorted_params = params.sort {|x,y| x[0] <=> y[0]}
      encoded_params = sorted_params.collect do |p|
        encoded = (CGI::escape(p[0].to_s) +
                   "=" + CGI::escape(p[1].to_s))
        # Ensure spaces are encoded as '%20', not '+'
        encoded = encoded.gsub('+', '%20')
        # According to RFC3986 (the scheme for values expected by signing requests), '~'
        # should not be encoded
        encoded = encoded.gsub('%7E', '~')
      end
      sigquery = encoded_params.join("&")

      # Generate the request description string
      req_desc =
        method + "\n" +
        host + "\n" +
        base + "\n" +
        sigquery

    end

    # Encodes the given string with the secret_access_key by taking the
    # hmac-sha1 sum, and then base64 encoding it.  Optionally, it will also
    # url encode the result of that to protect the string if it's going to
    # be used as a query string parameter.
    #
    # @param [String] secret_access_key the user's secret access key for signing.
    # @param [String] str the string to be hashed and encoded.
    # @param [Boolean] urlencode whether or not to url encode the result., true or false
    # @return [String] the signed and encoded string.
    def encode(secret_access_key, str, urlencode=true)
      digest = OpenSSL::Digest::Digest.new('sha256')
      b64_hmac =
        Base64.encode64(
          OpenSSL::HMAC.digest(digest, secret_access_key, str)).gsub("\n","")

      if urlencode
        return CGI::escape(b64_hmac)
      else
        return b64_hmac
      end
    end
  end

end
