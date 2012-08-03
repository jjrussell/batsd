class Job::QueueCalculateShowRateController < Job::SqsReaderController

  def initialize
    super QueueNames::CALCULATE_SHOW_RATE
  end

  private

  def on_message(message)
    offer = Offer.find(message.body)

    return if offer.payment == 0
    log_info = true

    offer.calculate_conversion_rate!(log_info)
    conversion_rate = offer.calculated_conversion_rate

    offer.calculate_min_conversion_rate!
    if offer.has_low_conversion_rate? and offer.send_low_conversion_email?
      stats = {
        :recent_clicks => offer.recent_clicks,
        :recent_installs => offer.recent_installs,
        :conversion_rate => conversion_rate,
        :min_conversion_rate => offer.calculated_min_conversion_rate,
      }
      TapjoyMailer.deliver_low_conversion_rate_warning(offer, stats)
    end

    new_show_rate = offer.calculate_original_show_rate({}, log_info)

    offer.conversion_rate = conversion_rate
    offer.show_rate = new_show_rate
    offer.save!
  end

end
