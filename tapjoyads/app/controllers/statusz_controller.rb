class StatuszController < ApplicationController
  include AuthenticationHelper
  include MemcachedHelper
  include RightAws

  before_filter 'basic_authenticate'
  
  def index
    sdb = SdbInterface.new(nil, nil, {:multi_thread => true, :port => 80, :protocol => 'http'})

    @domain_save_freq = {}
    
    sdb.list_domains do |result|
      result.domains.each do |domain_name|
        @domain_save_freq[domain_name] = get_count_in_cache(
            "savefreq.#{domain_name}.#{((Time.now.to_i - 1.minutes) / 1.minutes).to_i}")
      end
    end
  rescue Exception => e
    render :text => "Exception: #{e}"
  end
  
  def queue_check
    queue = SqsGen2.new.queue(QueueNames::CONVERSION_TRACKING)
    
    result = "success"
    if queue.size > 1000
      result = "too long"
    end
    
    render :text => result
  end
  
end
