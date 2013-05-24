RIAK_NODES ||= [{host: ENV['RIAK_HOST']}] || []
DEVICE_RIAK_NODES ||= RIAK_NODES

if ENV['ASYNC']
  class Riak::Client::ProtobuffsBackend
    private
    def new_socket
      EM::Synchrony::TCPSocket.new(@node.host, @node.pb_port).tap do |socket|
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      end
    end
  end
end

Riak.escaper = "cgi"
if Rails.env.production? || (ENV['ASYNC'] && RIAK_NODES.any? && DEVICE_RIAK_NODES.any?)
  $riak = Riak::Client.new(:protocol => 'pbc', :nodes => RIAK_NODES)
  $riak_devices = Riak::Client.new(:protocol => 'pbc', :nodes => DEVICE_RIAK_NODES)
else
  $riak = $riak_devices = if ENV['RIAK_HOST']
    Riak::Client.new(
      :protocol => 'pbc',
      :nodes    => [{:host => ENV['RIAK_HOST']}]
    )
  else
    Riak::Client.new
  end
end
