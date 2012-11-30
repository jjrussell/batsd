# This job will queue up every partner to aggregate its offers' hourly stats.

class Job::MasterHourlyPartnerStatsController < Job::JobController

  def index
    Partner.find_in_batches(:batch_size => StatsAggregation::PARTNERS_PER_MESSAGE) do |partners|
      partner_ids = partners.map(&:id)
      Sqs.send_message(QueueNames::PARTNER_STATS_HOURLY, partner_ids.to_json)
    end

    render :text => 'ok'
  end

end
