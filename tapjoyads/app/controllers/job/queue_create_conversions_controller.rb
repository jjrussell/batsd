class Job::QueueCreateConversionsController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_CONVERSIONS
  end

  private

  def on_message(message)
    reward = Reward.find(message.body, :consistent => true)
    http_request = nil
    if reward.nil? # message may be a JSON string
      message = JSON.parse(message.body).symbolize_keys
      reward = Reward.find(message[:reward_key], :consistent => true)
      raise "Reward not found: #{message[:reward_key]}" if reward.nil?
    end

    reward.build_conversions.each do |c|
      save_conversion(c)
    end

    if message.is_a?(Hash) && reward.offer.conversion_tracking_urls.any?
      http_request = ActionController::Request.new({}) # simulate 'connect' http request

      # set up proper request url (will be used as 'Referer' HTTP header)
      # if no request_url provided, use a fake one
      http_request.env['REQUEST_URL'] = (message[:request_url] || 'https://api.tapjoy.com/connect')
      def http_request.url; @env['REQUEST_URL']; end

      # replace certain http headers with click values, since conversion requests often come from servers,
      # whereas clicks come from end users' devices which is the info we want to pass along
      %w(user_agent x_do_not_track dnt).each do |header|
        http_request.env["HTTP_#{header.upcase}"] = reward.click.send("#{header}_header")
      end

      reward.offer.queue_conversion_tracking_requests(http_request, reward.created.to_i.to_s)
    end
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
