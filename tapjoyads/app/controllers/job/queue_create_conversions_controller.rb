class Job::QueueCreateConversionsController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_CONVERSIONS
  end

  private

  def on_message(message)
    reward = Reward.find(message.body, :consistent => true)
    raise "Reward not found: #{message.body}" if reward.nil?

    reward.build_conversions.each do |c|
      save_conversion(c)
    end

    reward.offer.queue_conversion_tracking_requests(reward.created.to_i.to_s)
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
