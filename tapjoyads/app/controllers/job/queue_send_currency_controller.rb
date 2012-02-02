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
    # TO REMOVE: once all the messages with a serialized reward are gone
    if message.body =~ /^\{.*\}$/
      reward = Reward.deserialize(message.body)
    else
      reward = Reward.find(message.body, :consistent => true)
      raise "Reward not found: #{message.body}" if reward.nil?
    end
    return if reward.sent_currency? && reward.send_currency_status?

    mc_time = Time.zone.now.to_i / 1.hour
    if @bad_callbacks.include?(reward.currency_id)
      @num_reads += 1 if @num_reads < @max_reads
      Mc.increment_count("send_currency_skip.#{reward.currency_id}.#{mc_time}")
      raise SkippedSendCurrency.new("not attempting to ping the callback for #{reward.currency_id}")
    end

    currency = Currency.find_in_cache(reward.currency_id, true)
    publisher_user_id = reward.publisher_user_id
    callback_url = currency.callback_url

    if callback_url == Currency::PLAYDOM_CALLBACK_URL
      first_char = publisher_user_id[0, 1]
      publisher_user_id = publisher_user_id[1..-1]

      if first_char == 'F'
        callback_url = 'http://offer-dynamic-lb.playdom.com/tapjoy/mob/facebook/fp/main' # facebook url
      elsif first_char == 'M' || first_char == 'P'
        callback_url = 'http://offer-dynamic-lb.playdom.com/tapjoy/mob/myspace/fp/main' # myspace/iphone url
      else
        reward.send_currency_status = 'InvalidPlaydomUserId'
        reward.serial_save
        return
      end
    end

    unless callback_url == Currency::TAPJOY_MANAGED_CALLBACK_URL
      mark = '?'
      mark = '&' if callback_url =~ /\?/
      callback_url += mark
      url_params = [
        "snuid=#{CGI::escape(publisher_user_id)}",
        "currency=#{reward.currency_reward}",
      ]
      if currency.send_offer_data?
        offer = Offer.find_in_cache(reward.offer_id, true)
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

    reward.sent_currency = Time.zone.now

    begin
      reward.serial_save(:catch_exceptions => false, :expected_attr => {'sent_currency' => nil})
    rescue Simpledb::ExpectedAttributeError => e
      reward = Reward.new(:key => reward.key, :consistent => true)
      if reward.send_currency_status?
        return
      else
        raise e
      end
    end

    begin
      if currency.callback_url == Currency::TAPJOY_MANAGED_CALLBACK_URL
        params[:callback_url] = Currency::TAPJOY_MANAGED_CALLBACK_URL
        PointPurchases.transaction(:key => "#{publisher_user_id}.#{reward.publisher_app_id}") do |point_purchases|
          point_purchases.points = point_purchases.points + reward.currency_reward
        end
        reward.send_currency_status = 'OK'
      else
        params[:callback_url] = callback_url
        begin
          if Rails.env.production? || Rails.env.test?
            response = Downloader.get_strict(callback_url, { :timeout => 20 })
            status = response.status
          else
            status = 'OK'
          end
          reward.send_currency_status = status
        rescue Exception => e
          @bad_callbacks << reward.currency_id
          raise e
        end
      end
      params.delete(:callback_url)
    rescue Exception => e
      reward.delete('sent_currency')
      reward.serial_save

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

    reward.serial_save
  end

end
