class StatuszController < ApplicationController
  include AuthenticationHelper

  before_filter 'basic_authenticate', :only => [ :queue_check, :slave_db_check, :memcached_check, :master_healthz ]

  def index
    render :text => "ok"
  end

  def queue_check
    queues = {
      :hourly_app_stats    => (Sqs.queue(QueueNames::APP_STATS_HOURLY).visible_messages < 2_000),
      :daily_app_stats     => (Sqs.queue(QueueNames::APP_STATS_DAILY).visible_messages < 1_000),
      :conversion_tracking => (Sqs.queue(QueueNames::CONVERSION_TRACKING).visible_messages < 10_000),
      :create_conversions  => (Sqs.queue(QueueNames::CREATE_CONVERSIONS).visible_messages < 10_000),
      #:failed_sdb_saves    => (Sqs.queue(QueueNames::FAILED_SDB_SAVES).visible_messages < 200_000),
      :send_currency       => (Sqs.queue(QueueNames::SEND_CURRENCY).visible_messages < 10_000),
    }.reject { |queue, under| under }

    render :json => queues, :status => queues.empty? ? :ok : :expectation_failed
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
