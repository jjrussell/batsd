class StatuszController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'basic_authenticate', :only => :queue_check
  
  def index
    render :text => "ok"
  end
  
  def queue_check
    conversion_tracking_queue = RightAws::SqsGen2.new.queue(QueueNames::CONVERSION_TRACKING)
    failed_sdb_saves_queue = RightAws::SqsGen2.new.queue(QueueNames::FAILED_SDB_SAVES)
    
    result = "success"
    if conversion_tracking_queue.size > 1000 || failed_sdb_saves_queue.size > 5000
      result = "too long"
    end
    
    render :text => result
  end
  
end
