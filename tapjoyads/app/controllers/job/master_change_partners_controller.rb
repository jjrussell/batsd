class Job::MasterChangePartnersController < Job::JobController

  def index
    PartnerChange.to_complete.find_each do |pc|
      Sqs.send_message(QueueNames::PARTNER_CHANGES, pc.id)
    end

    render :text => 'ok'
  end

end
