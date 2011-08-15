# Creates domains that will be used tomorrow

class Job::QueuePreCreateDomainsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::PRE_CREATE_DOMAINS
  end
  
  private
  
  def on_message(message)
    date_string = message.to_s
    
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      retries = 5
      begin
        SimpledbResource.create_domain("web-request-#{date_string}-#{num}")
      rescue Exception => e
        if retries > 0
          retries -= 1
          sleep 1
          retry
        end
        raise e
      end
    end
  end
end
