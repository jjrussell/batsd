class StatuszController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'basic_authenticate', :only => [ :queue_check, :slave_db_check ]
  
  def index
    render :text => "ok"
  end
  
  def queue_check
    hourly_app_stats_queue         = Sqs.queue(QueueNames::APP_STATS_HOURLY)
    daily_app_stats_queue          = Sqs.queue(QueueNames::APP_STATS_DAILY)
    conversion_tracking_queue      = Sqs.queue(QueueNames::CONVERSION_TRACKING)
    send_money_txn_queue           = Sqs.queue(QueueNames::SEND_MONEY_TXN)
    failed_sdb_saves_queue         = Sqs.queue(QueueNames::FAILED_SDB_SAVES)
    failed_device_saves_queue      = Sqs.queue(QueueNames::FAILED_DEVICE_SAVES)
    failed_web_request_saves_queue = Sqs.queue(QueueNames::FAILED_WEB_REQUEST_SAVES)
    
    result = "success"
    if hourly_app_stats_queue.size > 1000 ||
       daily_app_stats_queue.size > 1000 ||
       conversion_tracking_queue.size > 1000 ||
       send_money_txn_queue.size > 1000 ||
       failed_sdb_saves_queue.size > 5000 ||
       failed_device_saves_queue.size > 5000 ||
       failed_web_request_saves_queue.size > 5000
      result = "too long"
    end
    
    render :text => result
  end
  
  def slave_db_check
    result = "success"
    
    User.using_slave_db do
      hash = User.slave_connection.execute("SHOW SLAVE STATUS").fetch_hash
      if hash['Slave_IO_Running'] != 'Yes' || hash['Slave_SQL_Running'] != 'Yes' || hash['Seconds_Behind_Master'].to_i > 300
        result = 'fail'
      end
    end
    
    render :text => result
  end
  
end
