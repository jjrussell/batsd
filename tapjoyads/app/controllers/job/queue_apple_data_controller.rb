class Job::QueueAppleDataController < Job::SqsReaderController
  
  def initialize
    super 'AppleData'
    @num_reads = 1
  end
  
private
  
  def on_message(message)
    domain_name = message.to_s
    message.delete
    count = 0
    counts = {}
    start = Time.zone.now.beginning_of_year
    finish = start + 3.months
    Reward.select(:domain_name => domain_name, :where => "created >= '#{start.to_i}' AND created < '#{finish.to_i}'") do |r|
      count += 1
      Rails.logger.info "**************************************** #{Time.zone.now.to_s(:db)} - looked at #{count} rewards" if count % 1000 == 0
      next unless r.udid =~ /^[a-f0-9]{40}$/
      counts[r.udid] ||= 0
      counts[r.udid] += 1
    end
    b = S3.bucket(BucketNames::TAPJOY)
    b.put("apple_data/#{domain_name}.json", counts.to_json)
  end
  
end
