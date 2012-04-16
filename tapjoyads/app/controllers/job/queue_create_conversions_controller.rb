class Job::QueueCreateConversionsController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_CONVERSIONS
  end

  private

  def on_message(message)
    reward = Reward.find(message.body, :consistent => true)
    if reward.nil? # message may be a JSON string
      message = JSON.parse(message.body).symbolize_keys
      reward = Reward.find(message[:reward_key], :consistent => true)
      raise "Reward not found: #{message[:reward_key]}" if reward.nil?
    end

    reward.build_conversions.each do |c|
      save_conversion(c)
    end

    if message.is_a?(Hash)
      referer_url = (message[:request_url] || 'https://api.tapjoy.com/connect')
      reward.offer.queue_conversion_tracking_requests(referer_url)
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
