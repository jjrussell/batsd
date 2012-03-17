class Job::QueueSuspiciousGamerEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SUSPICIOUS_GAMERS
  end

  private

  def on_message(message)
    data = JSON.load(message.body)
    gamer_id = data[:gamer_id]
    gamer = Gamer.find(gamer_id)
    gamer_email = gamer.email
    behavior_type = data[:behavior_type]
    behavior_result = data[:behavior_result]
    TapjoyMailer.deliver_suspicious_gamer_alert(gamer_id, gamer_email, behavior_type, behavior_result)
  end
end
