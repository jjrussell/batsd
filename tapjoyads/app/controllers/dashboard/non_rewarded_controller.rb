class Dashboard::NonRewardedController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :setup
  before_filter :check_tos, :only => [ :create ]

  after_filter :save_activity_logs, :only => [ :create, :update ]

  def show
    if @currency
      render :edit
    else
      render :new
    end
  end

  def new
    redirect_to edit_app_non_rewarded_path(:app_id => @app.id) if @currency
  end

  def edit
    redirect_to new_app_non_rewarded_path(:app_id => @app.id) unless @currency
  end

  def create
    unless @currency
      @currency = @app.build_non_rewarded
      if @currency.save
        flash[:notice] = "Non-rewarded has been created." # TODO i18n
      else
        flash.now[:error] = "Could not create non-rewarded." # TODO i18n
      end
    end
    redirect_to app_non_rewarded_path(:app_id => @app.id)
  end

  def update
    @currency or (redirect_to(new_app_non_rewarded_path(:app_id => @app.id)) and return)
    allowed_attr_names = [ :test_devices, :minimum_offerwall_bid, :minimum_featured_bid, :minimum_display_bid ]
    if permitted_to?(:edit, :dashboard_statz)
      allowed_attr_names += [ :tapjoy_enabled, :hide_rewarded_app_installs, :minimum_hide_rewarded_app_installs_version, :disabled_offers, :max_age_rating, :only_free_offers, :send_offer_data, :ordinal, :rev_share_override ]
    end
    begin
      @currency.safe_update_attributes(params[:currency], allowed_attr_names)
      flash[:notice] = "Non-rewarded has been updated." # TODO i18n
    rescue
      flash.now[:error] = "Could not update non-rewarded."  # TODO i18n
    end
    redirect_to app_non_rewarded_path(:app_id => @app.id)
  end

  private

  def check_tos
    unless @partner.accepted_publisher_tos?
      if params[:terms_of_service] == '1'
        log_activity(@partner)
        @partner.update_attribute :accepted_publisher_tos, true
      else
        flash[:error] = 'You must accept the terms of service to set up non-rewarded.'  # TODO i18n
        redirect_to app_non_rewarded_path(:app_id => @app.id)
      end
    end
  end

  def setup
    @app      = App.find(params[:app_id])
    @partner  = @app.partner
    @currency = @app.non_rewarded
  end

end
