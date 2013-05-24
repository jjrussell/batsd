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
      allowed_attr_names += [ :tapjoy_enabled, :hide_rewarded_app_installs, :disabled_offers, :max_age_rating, :only_free_offers, :send_offer_data, :ordinal, :rev_share_override, :offer_filter_selections, :use_offer_filter_selections, :conversion_rate_enabled, :message, :message_enabled ]
    end

    record_was_valid = true

    begin
      params[:currency] = sanitize_currency_params(params[:currency], [ :minimum_featured_bid, :minimum_offerwall_bid, :minimum_display_bid ])
      record_was_valid = @currency.safe_update_attributes(params[:currency], allowed_attr_names)
    rescue
      # Exception will have been raised due to insufficient permission
      flash.now[:error] = "Could not update non-rewarded."  # TODO i18n
    end

    if !record_was_valid
      flash.now[:error] = "There were errors saving your record" # TODO i18n
      render :edit and return
    else
      # The save may have still failed here, but it's not a validation fail
      # so let original (lack of) error handling happen
      flash[:notice] = "Non-rewarded has been updated." unless flash.now[:error] # TODO i18n
      redirect_to app_non_rewarded_path(:app_id => @app.id)
    end
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
