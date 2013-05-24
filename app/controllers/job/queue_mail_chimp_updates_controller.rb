class Job::QueueMailChimpUpdatesController < Job::SqsReaderController

  def initialize
    super QueueNames::MAIL_CHIMP_UPDATES
  end

  private

  def on_message(message)
    json = JSON.load(message.body)
    case json["type"]
    when "update"
      MailChimp.update(json["email"], json["merge_tags"])
    # todo: remove "create" in a day or so
    when "create"
      MailChimp.add_partner(Partner.find_by_id(json["partner_id"]))
    when "add_user"
      MailChimp.add_user(User.find_by_id(json["user_id"]))
    end
  end

end
