class StatuszController < ApplicationController
  include AuthenticationHelper

  before_filter 'basic_authenticate', :only => [ :queue_check, :slave_db_check, :memcached_check, :master_healthz ]

  def index
    render :text => "ok"
  end

  def queue_check
    hourly_app_stats_queue    = Sqs.queue(QueueNames::APP_STATS_HOURLY)
    daily_app_stats_queue     = Sqs.queue(QueueNames::APP_STATS_DAILY)
    conversion_tracking_queue = Sqs.queue(QueueNames::CONVERSION_TRACKING)
    create_conversions_queue  = Sqs.queue(QueueNames::CREATE_CONVERSIONS)
    failed_sdb_saves_queue    = Sqs.queue(QueueNames::FAILED_SDB_SAVES)
    send_currency_queue       = Sqs.queue(QueueNames::SEND_CURRENCY)

    result = "success"
    if hourly_app_stats_queue.size > 1000 ||
       daily_app_stats_queue.size > 1000 ||
       conversion_tracking_queue.size > 1000 ||
       create_conversions_queue.size > 1000 ||
       failed_sdb_saves_queue.size > 1000 ||
       send_currency_queue.size > 5000
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

  def memcached_check
    result = 'success'

    mc_stats = Mc.cache.stats
    if mc_stats[:pid].size != MEMCACHE_SERVERS.size
      result = 'fail'
    end

    render :text => result
  end

  def master_healthz
    epoch = File.read(MASTER_HEALTHZ_FILE)
    last_updated_at = Time.zone.at(epoch.to_i)

    render :text => last_updated_at < Time.zone.now - 2.minutes ? 'fail' : 'success'
  end

end
