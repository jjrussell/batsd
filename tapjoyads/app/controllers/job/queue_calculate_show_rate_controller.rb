class Job::QueueCalculateShowRateController < Job::SqsReaderController

  def initialize
    super QueueNames::CALCULATE_SHOW_RATE
  end

  private

  def on_message(message)
    offer = Offer.find(message.body)

    return if offer.payment == 0
    algorithm_id, log_info = Offer::EVEN_DISTRIBUTION_SHOW_RATE_ALGO_ID, true

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

    new_show_rate = offer.recalculate_show_rate(algorithm_id, {}, log_info)

    offer.conversion_rate = conversion_rate
    offer.show_rate = new_show_rate
    offer.save!
  end

end
