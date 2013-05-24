# This job verifies that hourly stats are getting populated in SimpleDB and in
# Couchbase by spot checking the stats for a single offer.

class Job::MasterVerifyHourlyStatsController < Job::JobController

  def index
    check = StatsAggregation.verify_nonzero_hourly_stats(params[:offer_id])
    Notifier.alert_new_relic(UnverifiedStatsError, check[:message], request, params) if check[:missing]
    render :text => 'ok'
  end

end
