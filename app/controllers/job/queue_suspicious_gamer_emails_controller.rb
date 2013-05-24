class Job::QueueSuspiciousGamerEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SUSPICIOUS_GAMERS
  end

  private

  def on_message(message)
    data = JSON.load(message.body)
    gamer = Gamer.find(data[:gamer_id])
    TapjoyMailer.deliver_suspicious_gamer_alert(gamer.id, gamer.email, data[:behavior_type], data[:behavior_result])
  end
end
