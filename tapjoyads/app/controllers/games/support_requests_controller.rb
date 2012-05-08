class Games::SupportRequestsController < GamesController
  before_filter :set_tracking_param

  def new
    current_gamer
  end

  def create
    @gamer = Gamer.find_by_email(current_gamer.email)
    data = params[:support_requests]

    if data[:content].blank?
      # Pull unresolved offers list from hidden field to avoid repeating SimpleDB query
      @clicks_list = params[:clicks_list]

      flash.now[:notice] = t("text.games.enter_message");
      render :new and return
    end

    # Retrieve relevant objects
    click = nil
    if params[:click_id].present?
      click = Click.new(:key => params[:click_id])
    end

    support_request = SupportRequest.new
    support_request.fill_from_click(click, params, current_device, @gamer, request.env["HTTP_USER_AGENT"])
    support_request.save

    case params[:type]
    when "feedback"
      GamesMailer.deliver_feedback(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "report_bug"
      GamesMailer.deliver_report_bug(@gamer, data[:content], request.env["HTTP_USER_AGENT"], current_device_id)
    when "contact_support"
      GamesMailer.deliver_contact_support(@gamer, current_device, data[:content], request.env["HTTP_USER_AGENT"], params[:language_code], click, support_request)
    else
      GamesMailer.deliver_contact_support(@gamer, current_device, data[:content], request.env["HTTP_USER_AGENT"], params[:language_code], click, support_request)
    end
  end

  def unresolved_clicks
    find_unresolved_clicks
    render(:partial => 'select_offer', :layout => false)
  end

  private

  def find_unresolved_clicks
    conditions = ActiveRecord::Base.sanitize_conditions("udid = ? and clicked_at > ? and manually_resolved_at is null", params[:udid], 30.days.ago.to_f.to_s)
    clicks = Click.select_all(:conditions => conditions).sort_by { |click| -click.clicked_at.to_f }

    @unresolved_clicks = []
    clicks.each do |click|
      if click.advertiser_app.present? && !@unresolved_clicks.any? { |clk| clk.advertiser_app_id == click.advertiser_app_id }
        @unresolved_clicks << click
      end

      break if @unresolved_clicks.length == 20
    end

    @unresolved_clicks.compact
  end

  def set_tracking_param
    @tjm_request.tracking_param = params[:type] if @tjm_request.present?
  end
end
