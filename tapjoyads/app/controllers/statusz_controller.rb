class StatuszController < ApplicationController
  include AuthenticationHelper
  include RightAws
  
  before_filter 'basic_authenticate', :only => :queue_check
  
  def index
    render :text => "ok"
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
