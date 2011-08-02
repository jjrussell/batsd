class Activemq
  
  MAX_FAILURES = 10
  RETRY_DELAY  = 5.minutes.to_i
  
  def self.reset_connection
    @@publishing_clients = ACTIVEMQ_SERVERS.map do |server|
      begin
        client = { :failures => 0 }
        Timeout.timeout(5) { client[:client] = Stomp::Client.new('', '', server, 61613, true) }
        client
      rescue Exception => e
        Notifier.alert_new_relic(e.class, e.message)
        nil
      end
    end
    @@publishing_clients.compact!
  end
  
  cattr_reader :publishing_clients
  self.reset_connection
  
  def self.publish_message(queue, message, fail_to_sqs = true)
    now = Time.now.utc
    client = nil
    available_clients = @@publishing_clients.reject { |c| c[:failures] >= MAX_FAILURES && c[:retry_at] > now }.sort_by{ rand }
    begin
      client = available_clients.pop
      raise "No Activemq clients available!" if client.nil?
      Timeout.timeout(5) { client[:client].publish("/queue/#{queue}", message, { :persistent => true, :suppress_content_length => true }) }
      client[:failures] = 0
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message) if Rails.env == 'production'
      if client.present?
        client[:failures] += 1
        client[:retry_at] = now + RETRY_DELAY if client[:failures] >= MAX_FAILURES
      end
      if available_clients.empty?
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
