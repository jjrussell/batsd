class Job::QueueResolveSupportRequestsController < Job::SqsReaderController

  def initialize
    super QueueNames::RESOLVE_SUPPORT_REQUESTS
    @num_reads = 5
  end

  private

  def on_message(message)
    request_not_awarded = []
    request_successfully_awarded = 0

    json = JSON.load(message.body)
    support_requests_file = S3.bucket(BucketNames::SUPPORT_REQUESTS).objects[json['support_requests_file']]
    support_requests_file.read.split.each do |support_request_id|
      support_request_id.strip!
      next if support_request_id.empty?

      support_request = SupportRequest.new(:key => support_request_id)
      if support_request.new_record?
        request_not_awarded.push([support_request_id, "Invalid support_request_id: #{support_request_id}"])
        next
      end

      click = support_request.click
      if click.nil?
        request_not_awarded.push([support_request_id, "Unable to find a suitable click for: #{support_request_id}"])
        next
      end

      begin
        log_activity(click)
        click.resolve!
      rescue Exception => error
        request_not_awarded.push([support_request_id, error])
        next
      end
      request_successfully_awarded += 1
    end
    save_activity_logs(true)
    TapjoyMailer.deliver_resolve_support_requests(json['user_email'], { :successfully_awarded_num => request_successfully_awarded, :requests_not_awarded => request_not_awarded }, support_requests_file.last_modified)
    support_requests_file.delete
  end
end
