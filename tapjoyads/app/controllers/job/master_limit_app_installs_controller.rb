class Job::MasterLimitAppInstallsController < Job::JobController
  def index
    publisher_app_ids = Currency.scoped(:select => :app_id).collect(&:app_id).uniq
    advertiser_app_ids = Offer.enabled_offers.free_apps.for_ios_only.scoped(:select => :item_id).collect(&:item_id).uniq
    Mc.put('enabled_free_app_ids', advertiser_app_ids)
    
    publisher_app_ids.each do |publisher_app_id|
      Sqs.send_message(QueueNames::LIMIT_APP_INSTALLS, publisher_app_id)
    end
    
    render :text => 'ok'
  end
end
