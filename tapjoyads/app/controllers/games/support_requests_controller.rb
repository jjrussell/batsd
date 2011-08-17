class Games::SupportRequestsController < GamesController
  
  def new
  end
  
  def create
    @gamer = Gamer.find_by_email(current_gamer.email)
    data = params[:support_requests]
    case params[:type]
    when "feedback"
      GamesMailer.deliver_feedback(@gamer, data[:content], request.env["HTTP_USER_AGENT"])
    when "report_bug"
      GamesMailer.deliver_report_bug(@gamer, data[:content], request.env["HTTP_USER_AGENT"])
    when "contact_support"
      GamesMailer.deliver_contact_support(@gamer, data[:content], request.env["HTTP_USER_AGENT"])
    else
      GamesMailer.deliver_contact_support(@gamer, data[:content], request.env["HTTP_USER_AGENT"])
    end
  end

end