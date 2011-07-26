class Activemq
  
  def self.reset_connection
    @@publishing_clients = ACTIVEMQ_SERVERS.map do |server|
      begin
        Timeout.timeout(5) { Stomp::Client.new('', '', server, 61613, false) }
      rescue Exception => e
        Notifier.alert_new_relic(e.class, e.message)
        nil
      end
    end
    @@publishing_clients.compact!
  end
  
  cattr_accessor :publishing_clients
  self.reset_connection
  
  def self.publish_message(queue, message, fail_to_sqs = true)
    attempt_order = (0...@@publishing_clients.size).to_a.sort_by { rand }
    begin
      @@publishing_clients[attempt_order.pop].publish("/queue/#{queue}", message, { :persistent => true })
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message) if Rails.env == 'production'
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
  
  def self.get_consumer(server, queue, options = {}, &block)
    ack_type      = options.delete(:ack_type)      { 'client' }
    prefetch_size = options.delete(:prefetch_size) { 1 }
    transaction   = options.delete(:transaction)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    consumer = Stomp::Client.new('', '', server, 61613, false)
    consumer.begin(transaction) if transaction.present?
    consumer.subscribe("/queue/#{queue}", { :ack => ack_type, 'activemq.prefetchSize' => prefetch_size }) do |message|
      yield(message)
    end
    consumer
  end
  
end
