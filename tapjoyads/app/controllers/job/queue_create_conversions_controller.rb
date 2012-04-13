class Job::QueueCreateConversionsController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_CONVERSIONS
  end

  private

  def on_message(message)
    reward = Reward.find(message.body, :consistent => true)
    http_request = nil
    if reward.nil? # message may be a JSON string
      message = JSON.parse(message).symbolize_keys
      reward = Reward.find(message[:reward_id], :consistent => true)
      raise "Reward not found: #{message.body}" if reward.nil?

      # handle third-party conversion pings
      if reward.offer.conversion_tracking_urls.any?
        # if no request_url provided,
        # provide a fake one
        request_env = { 'REQUEST_URL' => (message[:request_url] || 'https://api.tapjoy.com/connect') }

        # replace certain http headers with click values, since conversion requests often come from servers,
        # whereas clicks come from end users' devices
        %w(user_agent x_do_not_track dnt).each do |header|
          request_env["HTTP_#{header.upcase}"] = click.send("#{header}_header")
        end

        http_request = ActionController::Request.new(request_env)
        def http_request.url; @env['REQUEST_URL']; end
      end
    end

    reward.build_conversions(http_request).each do |c|
      save_conversion(c)
    end

    # for third party tracking vendors
    # note: we can't use a "belongs_to" relationship for sdb objects b/c it won't
    # allow modification of the object, as it's written currently
    offer = Offer.find(reward.offer_id)
    offer.queue_conversion_tracking_requests(reward.created.to_i.to_s)
  end

  def save_conversion(conversion)
    begin
      conversion.save!
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      if conversion.errors[:id] == 'has already been taken' || e.message =~ /Duplicate entry.*index_conversions_on_id/
        Rails.logger.info "Duplicate Conversion: #{e.class} when saving conversion: '#{conversion.id}'"
      else
        raise e
      end
    end
  end

end
