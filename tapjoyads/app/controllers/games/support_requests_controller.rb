class Games::SupportRequestsController < GamesController

  def new
  end

  def create
    @gamer = Gamer.find_by_email(current_gamer.email)
    data = params[:support_requests]
    case params[:type]
    when "feedback"
      GamesMailer.deliver_feedback(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "report_bug"
      GamesMailer.deliver_report_bug(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "contact_support"
      GamesMailer.deliver_contact_support(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    else
      GamesMailer.deliver_contact_support(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    end
  end

end
