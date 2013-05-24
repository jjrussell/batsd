class Job::QueueSendCurrencyController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_CURRENCY
    @raise_on_error = false
    @max_reads = @num_reads * 2
    @bad_callbacks = Set.new
  end

  private

  def on_message(message)
    params.delete(:callback_url)
    reward = Reward.find(message.body, :consistent => true)
    raise "Reward not found: #{message.body}" if reward.nil?
    return if reward.sent_currency? && reward.send_currency_status?

    mc_time = Time.zone.now.to_i / 1.hour
    if @bad_callbacks.include?(reward.currency_id)
      @num_reads += 1 if @num_reads < @max_reads
      Mc.increment_count("send_currency_skip.#{reward.currency_id}.#{mc_time}")
      raise SkippedSendCurrency.new("not attempting to ping the callback for #{reward.currency_id}")
    end

    currency = Currency.find_in_cache(reward.currency_id, :do_lookup => true)
    publisher_user_id = reward.publisher_user_id
    callback_url = currency.callback_url

    unless callback_url == Currency::TAPJOY_MANAGED_CALLBACK_URL
      mark = '?'
      mark = '&' if callback_url =~ /\?/
      callback_url += mark
      url_params = [
        "snuid=#{CGI::escape(publisher_user_id)}",
        "currency=#{reward.currency_reward}",
        "mac_address=#{reward.mac_address}",
      ]
      if currency.send_offer_data?
        offer = Offer.find_in_cache(reward.offer_id, :do_lookup => true)
        url_params += [
          "storeId=#{CGI::escape(offer.store_id_for_feed)}",
          "application=#{CGI::escape(offer.name)}",
          "rev=#{reward.publisher_amount / 100.0}",
        ]
      end
      if currency.secret_key.present?
        hash_bits = [
          reward.key,
          publisher_user_id,
          reward.currency_reward,
          currency.secret_key,
        ]
        hash = Digest::MD5.hexdigest(hash_bits.join(':'))
        url_params += [
          "id=#{reward.key}",
          "verifier=#{hash}",
        ]
      end
      callback_url += url_params.join('&')
    end

    @now = Time.zone.now
    reward.sent_currency = @now

    begin
      reward.save!(:expected_attr => {'sent_currency' => nil})
    rescue Simpledb::ExpectedAttributeError => e
      reward = Reward.new(:key => reward.key, :consistent => true)
      if reward.send_currency_status?
        return
      else
        Notifier.alert_new_relic(e.class, e.message, request, params.merge(:reward_id => reward.id))
        $redis.sadd 'queue:send_currency:failures', reward.key
        return
      end
    end

    begin
      if currency.callback_url == Currency::TAPJOY_MANAGED_CALLBACK_URL
        params[:callback_url] = Currency::TAPJOY_MANAGED_CALLBACK_URL
        PointPurchases.transaction(:key => "#{publisher_user_id}.#{reward.publisher_app_id}") do |point_purchases|
          point_purchases.points = point_purchases.points + reward.currency_reward
        end
        reward.send_currency_status = 'OK'
        send_notification(reward)
      else
        params[:callback_url] = callback_url
          if Rails.env.production? || Rails.env.test?
            start_time = Time.now                                                                   #TODO Need to use Benchmark.realtime for this,
            response = Downloader.get(callback_url, {:return_response => true, :timeout => 20 })    #but putting Downloader.get in a block breaks the scope for tests.
            http_response_time  = Time.now - start_time                                             #This code is the exact same thing Benchmark.realtime does.
            status = response.status

            options = {
              :callback_url => callback_url,
              :http_status_code => status,
              :http_response_time => http_response_time,
              :reward_id => reward.id,
              :publisher_app_id => reward.publisher_app_id,
              :currency_id => reward.currency_id,
              :amount => reward.currency_reward
            }

            web_request = WebRequest.new(:time => @now)
            web_request.put_values('send_currency_attempt', options)

            if status == 200
              reward.send_currency_status = status
              send_notification(reward)
            elsif status == 403
              reward.send_currency_status = status
              Notifier.alert_new_relic(FailedToDownloadError, "Failed to download #{callback_url}. 403 error.")
            else
              @bad_callbacks << reward.currency_id
            end

          else
            status = 'OK'
            send_notification(reward)
          end
      end
      params.delete(:callback_url)

    rescue Patron::TimeoutError, Exception => e
      @bad_callbacks << reward.currency_id
      reward.delete('sent_currency')
      reward.save

      num_failures = Mc.increment_count("send_currency_failure.#{currency.id}.#{mc_time}")
      if num_failures < 5000
        Mc.compare_and_swap("send_currency_failures.#{mc_time}") do |failures|
          failures ||= {}
          failures[currency.id] ||= Set.new
          failures[currency.id] << reward.key
          failures
        end
      end

      raise e
    end

    reward.save
  end

  def send_notification(reward)
    if reward.offer.try(:should_notify_on_conversion?)
      publisher_app = App.find_in_cache(reward.publisher_app_id)
      Sqs.send_message(QueueNames::CONVERSION_NOTIFICATIONS, reward.id) if publisher_app && publisher_app.notifications_enabled?
    end
  end
end
