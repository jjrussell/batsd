class Job::MasterCleanupWebRequestsController < Job::JobController

  def index
    day = Date.today - 2.days
    backup_options = { :delete_domain => true }
    domain_names = SimpledbResource.get_domain_names

    2.times do
      MAX_WEB_REQUEST_DOMAINS.times do |num|
        domain_name = "web-request-#{day.to_s}-#{num}"

        next unless domain_names.include?(domain_name)

        message = { :domain_name => domain_name, :s3_bucket => BucketNames::WEB_REQUESTS, :backup_options => backup_options }.to_json
        Sqs.send_message(QueueNames::SDB_BACKUPS, message)
      end

      day -= 7.days
    end

    render :text => 'ok'
  end

end
