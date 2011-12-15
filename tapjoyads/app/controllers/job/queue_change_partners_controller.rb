class Job::QueueChangePartnersController < Job::SqsReaderController

  def initialize
    super QueueNames::PARTNER_CHANGES
  end

  private

  def on_message(message)
    PartnerChange.transaction do
      pc = PartnerChange.find(message.body, :lock => 'FOR UPDATE')
      log_activity(pc)
      log_activity(pc.item)
      pc.complete!
      save_activity_logs(true)
    end
  end

end
