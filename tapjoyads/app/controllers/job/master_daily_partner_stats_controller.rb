# This job will queue up every partner to have its daily stats aggregated.

class Job::MasterDailyPartnerStatsController < Job::JobController

  def index
    Partner.find_in_batches(:batch_size => StatsAggregation::PARTNERS_PER_MESSAGE) do |partners|
      partner_ids = partners.map(&:id)
      Sqs.send_message(QueueNames::PARTNER_STATS_DAILY, partner_ids.to_json)
    end

    render :text => 'ok'
  end

end
