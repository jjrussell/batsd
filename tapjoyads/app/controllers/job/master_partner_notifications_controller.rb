class Job::MasterPartnerNotificationsController < Job::JobController
  
  def index
    Offer.enabled_offers.collect(&:partner_id).uniq.each do |partner_id|
      Sqs.send_message(QueueNames::PARTNER_NOTIFICATIONS, { :partner_id => partner_id }.to_json)
    end
    render :text => "ok"
  end
  
end
