class Games::SupportRequestsController < GamesController

  def new
    respond_to do |format|
      format.js do
        Rails.logger.info "Format: JS"
        find_incomplete_offers
        render(:partial => 'select_offer', :layout => false)
      end
      format.html do
        Rails.logger.info "Format: HTML"
        current_gamer
      end
    end
  end

  def create
    @gamer = Gamer.find_by_email(current_gamer.email)
    data = params[:support_requests]

    if data[:content].blank?
      flash.now[:notice] = t("text.games.enter_message");
      render :new and return
    end

    # Get the click of concern

    #support_request = SupportRequest.new
    #support_request.fill(params, @app, @currency, @offer)
    #support_request.save

    case params[:type]
    when "feedback"
      GamesMailer.deliver_feedback(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "report_bug"
      GamesMailer.deliver_report_bug(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "contact_support"
      GamesMailer.deliver_contact_support(@gamer, current_device, data[:content], request.env["HTTP_USER_AGENT"], params[:language_code])
    else
      GamesMailer.deliver_contact_support(@gamer, current_device, data[:content], request.env["HTTP_USER_AGENT"], params[:language_code])
    end
  end

end
