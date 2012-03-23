class Games::SupportRequestsController < GamesController

  def new
    respond_to do |format|
      format.js do
        find_unresolved_clicks
        render(:partial => 'select_offer', :layout => false)
      end
      format.html do
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

    # Retrieve relevant objects
    offer = params[:offer_id].present? ? Offer.find(params[:offer_id]) : nil

    # Build support request
    #support_request = SupportRequest.new
    #support_request.fill(params, @app, @currency, @offer)
    #support_request.save

    case params[:type]
    when "feedback"
      GamesMailer.deliver_feedback(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "report_bug"
      GamesMailer.deliver_report_bug(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "contact_support"
      GamesMailer.deliver_contact_support(@gamer, current_device, data[:content], request.env["HTTP_USER_AGENT"], params[:language_code], offer)
    else
      GamesMailer.deliver_contact_support(@gamer, current_device, data[:content], request.env["HTTP_USER_AGENT"], params[:language_code], offer)
    end
  end

  private

  def find_unresolved_clicks
    #conditions = ActiveRecord::Base.sanitize_conditions("udid = ? and clicked_at > ? and manually_resolved_at is null", params[:udid], 30.days.ago.to_f.to_s)
    conditions = ActiveRecord::Base.sanitize_conditions("udid = ? and clicked_at > ? and manually_resolved_at is null", "statz_test_udid", 30.days.ago.to_f.to_s)
    clicks = Click.select_all(:conditions => conditions).sort_by { |click| -click.clicked_at.to_f }

    @unresolved_clicks = []
    clicks.each do |click|
      if Offer.find_in_cache(click.advertiser_app_id, false).present? && !@unresolved_clicks.any? { |clk| clk.advertiser_app_id == click.advertiser_app_id }
        @unresolved_clicks << click
      end

      break if @unresolved_clicks.length == 20
    end.compact
  end
end
