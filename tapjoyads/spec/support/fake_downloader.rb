class FakeDownloader
  HOST_STATUS = {
    'http://working.com/'  => 200,
    'http://broken.com/'   => 500,
    'http://timeout.com/'  => lambda { raise Timeout::Error },
    'http://nosocket.com/' => lambda { raise SocketError },
    'http://refused.com/'  => lambda { raise Errno::ECONNREFUSED }
  }

  def self.get(path, options = {})
    response('get', path, options)
  end

  def self.post(path, options = {})
    response('post', path, options)
  end

  def self.response(method, path, options = {})
    status = HOST_STATUS.fetch(path) { nil }

    if status.is_a?(Integer)
      body = "#{method.upcase} #{path}" if status >= 200 && status <= 299

      OpenStruct.new({
        :body => body,
        :code => status
      })
    elsif status.is_a?(Proc)
      status.call
    else
      false
    end
  end
end
