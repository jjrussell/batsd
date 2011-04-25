class Job::QueueLimitAppInstallsController < Job::SqsReaderController

  def initialize
    super QueueNames::LIMIT_APP_INSTALLS
  end

  def on_message(message)
    publisher_app_id = message.to_s
    publisher_app = App.find(publisher_app_id)
    advertiser_app_ids = App.enabled_free_ios_apps
    capped_advertiser_app_ids = publisher_app.capped_advertiser_app_ids
    
    advertiser_app_ids.each do |advertiser_app_id|
      next if capped_advertiser_app_ids.include?(advertiser_app_id)
      daily_installs = publisher_app.daily_installs_for_advertiser(advertiser_app_id)
      capped_advertiser_app_ids << advertiser_app_id if (daily_installs.present? && daily_installs >= App::MAXIMUM_INSTALLS_PER_PUBLISHER)
    end
    
    publisher_app.set_capped_advertiser_app_ids(capped_advertiser_app_ids)
  end
end
