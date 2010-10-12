class StatuszController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'basic_authenticate', :only => [ :queue_check, :slave_db_check ]
  
  def index
    render :text => "ok"
  end
  
  def queue_check
    conversion_tracking_queue = Sqs.queue(QueueNames::CONVERSION_TRACKING)
    failed_sdb_saves_queue = Sqs.queue(QueueNames::FAILED_SDB_SAVES)
    
    result = "success"
    if conversion_tracking_queue.size > 1000 || failed_sdb_saves_queue.size > 5000
      result = "too long"
    end
    
    render :text => result
  end
  
  def slave_db_check
    result = "success"
    
    User.using_slave_db do
      hash = User.slave_connection.execute("SHOW SLAVE STATUS").fetch_hash
      if hash['Seconds_Behind_Master'].to_i > 300
        result = 'too far behind'
      end
    end
    
    render :text => result
  end
  
end
