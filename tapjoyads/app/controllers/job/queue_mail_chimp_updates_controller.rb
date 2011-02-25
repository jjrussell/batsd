class Job::QueueMailChimpUpdatesController < Job::SqsReaderController

  def initialize
    super QueueNames::MAIL_CHIMP_UPDATES
  end

private

  def on_message(message)
    message = JSON.load(message.to_s)
    case message["type"]
    when "update"
      MailChimp.update(message["email"], message["merge_tags"])
    # todo: remove "create" in a day or so
    when "create"
      MailChimp.add_partner(Partner.find_by_id(message["partner_id"]))
    when "add_user"
      MailChimp.add_user(User.find_by_id(message["user_id"]))
    end
  end
end
