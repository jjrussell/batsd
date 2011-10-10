class Job::MasterCleanupWebRequestsController < Job::JobController

  def index
    day = Date.today - 2.days
    domain_names = SimpledbResource.get_domain_names

    num_unverified = Offer.count(:conditions => [ "last_daily_stats_aggregation_time < ?",  day.tomorrow ])
    if num_unverified > 0
      error_message = "cannot backup web-requests for #{day}, there are #{num_unverified} offers with unverified stats"
      Notifier.alert_new_relic(UnverifiedStatsError, error_message, request, params)
      render :text => error_message
      return
    end

    3.times do
      MAX_WEB_REQUEST_DOMAINS.times do |num|
        domain_name = "web-request-#{day.to_s}-#{num}"

        next unless domain_names.include?(domain_name)

        SimpledbResource.delete_domain(domain_name)
      end

      day -= 1.day
    end

    render :text => 'ok'
  end

end
