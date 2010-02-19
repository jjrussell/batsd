class StatuszController < ApplicationController
  include AuthenticationHelper
  include MemcachedHelper
  include RightAws

  before_filter 'authenticate'
  
  def index
    sdb = SdbInterface.new(nil, nil, {:multi_thread => true, :port => 80, :protocol => 'http'})

    @domain_save_freq = {}
    
    sdb.list_domains do |result|
      result.domains.each do |domain_name|
        @domain_save_freq[domain_name] = get_count_in_cache(
            "savefreq.#{domain_name}.#{((Time.now.to_i - 1.minutes) / 1.minutes).to_i}")
      end
    end
  end
  
end
