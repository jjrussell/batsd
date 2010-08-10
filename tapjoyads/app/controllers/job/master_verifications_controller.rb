class Job::MasterVerificationsController < Job::JobController
  def index
    check_grab_advertiser_udids_logs
    check_partner_balances
    
    render :text => 'ok'
  end
  
private
  
  def check_grab_advertiser_udids_logs
    GrabAdvertiserUdidsLog.select(:where => "job_started_at < '#{(Time.zone.now - 1.day).to_i}' and job_finished_at is null") do |log|
      next if log.job_requeued_at && log.job_requeued_at < log.job_started_at
      
      log.job_requeued_at = Time.zone.now
      log.save
      
      message = { :offer_id => log.offer_id, :start_time => log.start_time, :finish_time => log.finish_time }.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
    end
  end
  
  def check_partner_balances
    day_of_week = Date.today.wday
    
    Partner.find_each do |partner|
      next unless partner.id.hash % 7 == day_of_week
      
      partner.recalculate_balances(false, true)
      sleep(2)
    end
  end
  
end
