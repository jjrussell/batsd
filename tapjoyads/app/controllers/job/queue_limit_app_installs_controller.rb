class Job::QueueLimitAppInstallsController < Job::SqsReaderController

  def initialize
    super QueueNames::LIMIT_APP_INSTALLS
  end

  def on_message(message)
    publisher_app_id = message.to_s
    publisher_app = App.find(publisher_app_id)
    advertiser_app_ids = Mc.get('enabled_free_app_ids')
    today = Time.zone.now.to_date.to_s
    capped_mc_key = "capped_app_installs.#{today}.#{publisher_app_id}"
    capped_advertiser_app_ids = Mc.get(capped_mc_key) || Set.new
    
    advertiser_app_ids.each do |advertiser_app_id|
      next if capped_advertiser_app_ids.include?(advertiser_app_id)
      mc_key = "app_installs_by_publisher.#{today}.#{publisher_app_id}.#{advertiser_app_id}"
      daily_installs = Mc.get_count(mc_key)
      capped_advertiser_app_ids << advertiser_app_id if (daily_installs.present? && daily_installs >= App::MAXIMUM_INSTALLS_PER_PUBLISHER)
    end
    
    Mc.put(capped_mc_key, capped_advertiser_app_ids)
  end
end
