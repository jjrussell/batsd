class Games::SupportRequestsController < GamesController

  before_filter :set_tracking_param

  def new
    current_gamer
  end

  def create
    @gamer = Gamer.find_by_email(current_gamer.email)
    data = params[:support_requests]

    if data[:content].blank?
      flash.now[:notice] = t("text.games.enter_message");
      render :new and return
    end

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

  private

  def set_tracking_param
    @tjm_request.tracking_param = params[:type] if @tjm_request.present?
  end
end
