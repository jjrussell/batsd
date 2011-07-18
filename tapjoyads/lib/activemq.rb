class Activemq
  
  def self.reset_connection
    @@publishing_clients = ACTIVEMQ_SERVERS.map do |server|
      Stomp::Client.new('', '', server, 61613, false)
    end
  end
  
  cattr_accessor :publishing_clients
  self.reset_connection
  
  def self.publish_message(queue, message, fail_to_sqs = true)
    attempt_order = (0...@@publishing_clients.size).to_a.sort_by { rand }
    begin
      @@publishing_clients[attempt_order.pop].publish("/queue/#{queue}", message, { :persistent => true })
    rescue Exception => e
      if attempt_order.empty?
        if fail_to_sqs
          sqs_message = { :queue => queue, :message => message }.to_json
          Sqs.send_message(QueueNames::FAILED_ACTIVEMQ_WRITES, sqs_message)
        else
          raise e
        end
      else
        retry
      end
    end
  end
  
  def self.get_consumer(server, queue, &block)
    consumer = Stomp::Client.new('', '', server, 61613, false)
    consumer.subscribe("/queue/#{queue}", { :ack => :client, 'activemq.prefetchSize' => 100000 }) do |message|
      yield(message)
    end
    consumer
  end
  
end
