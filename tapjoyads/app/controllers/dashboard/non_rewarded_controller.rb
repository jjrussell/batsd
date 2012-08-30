class Dashboard::NonRewardedController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :setup
  before_filter :check_tos, :except => [ :index ]

  after_filter :save_activity_logs, :only => [ :toggle ]

  def index
    unless @currency
      @currency = @app.build_non_rewarded
      @currency.save!
    end
  end

  def toggle
    @currency.tapjoy_enabled = !@currency.tapjoy_enabled
    if @currency.save
      flash[:notice] = "Non-rewarded has been #{@currency.tapjoy_enabled ? 'enabled' : 'disabled'}."
    else
      flash.now[:error] = "Could not #{@currency.tapjoy_enabled ? 'enable' : 'disable'} non-rewarded."
    end
    render :index
  end

  private

  def check_tos
    unless @partner.accepted_publisher_tos?
      if params[:terms_of_service] == '1'
        log_activity(@partner)
        @partner.update_attribute :accepted_publisher_tos, true
      else
        flash[:error] = 'You must accept the terms of service to set up non-rewarded.'
        render :index
      end
    end
  end

  def setup
    @app      = App.find(params[:app_id])
    @partner  = @app.partner
    @currency = @app.non_rewarded
  end

end
