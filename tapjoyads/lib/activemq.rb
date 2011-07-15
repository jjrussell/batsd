class Activemq
  
  def self.reset_connection
    @@publishing_clients = ACTIVEMQ_SERVERS.map do |server|
      Stomp::Client.new('activemq', 'somepassword', server, 61613, true)
    end
  end
  
  cattr_accessor :publishing_clients
  self.reset_connection
  
  def self.publish_message(queue, message, persistent = true)
    @@publishing_clients[rand(@@publishing_clients.size)].publish("/queue/#{queue}", message, { :persistent => persistent })
  end
  
  def self.get_consumer(server, queue, &block)
    consumer = Stomp::Client.new('activemq', 'somepassword', server, 61613, true)
    consumer.subscribe("/queue/#{queue}", { :ack => :client }) do |message|
      yield(message)
    end
    consumer
  end
  
end
