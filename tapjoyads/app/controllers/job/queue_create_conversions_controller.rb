class Job::QueueCreateConversionsController < Job::SqsReaderController

  def initialize
    super QueueNames::CREATE_CONVERSIONS

    # Raising on error means the job doesn't process the rest
    @raise_on_error = false
  end

  private

  def on_message(message)
    reward = Reward.find(message.body, :consistent => true)
    raise "Reward not found: #{message.body}" if reward.nil?

    reward.build_conversions.each do |c|
      save_conversion(c)
    end

    # for third party tracking vendors
    if reward.offer.conversion_tracking_urls.any? # only do click lookup if necessary
      reward.offer.queue_conversion_tracking_requests(:timestamp => reward.created.to_i, :ip_address => reward.click.try(:ip_address))
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
