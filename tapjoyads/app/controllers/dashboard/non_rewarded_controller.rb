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
    redirect_to :action => :edit if @currency
  end

  def edit
    redirect_to :action => :new unless @currency
  end

  def create
    unless @currency
      @currency = @app.build_non_rewarded
      if @currency.save
        flash[:notice] = "Non-rewarded has been created."
        redirect_to :action => :edit
      else
        flash.now[:error] = "Could not create non-rewarded."
        redirect_to :action => :new
      end
    end
  end

  def update
    if @currency
      allowed_attr_names = [ :test_devices, :minimum_offerwall_bid, :minimum_featured_bid, :minimum_display_bid ]
      if permitted_to?(:edit, :dashboard_statz)
        allowed_attr_names += [ :tapjoy_enabled, :hide_rewarded_app_installs, :minimum_hide_rewarded_app_installs_version, :disabled_offers, :max_age_rating, :only_free_offers, :send_offer_data, :ordinal, :rev_share_override ]
      end
      @currency.safe_update_attributes(params[:currency], allowed_attr_names)
      if @currency.save
        flash[:notice] = "Non-rewarded has been updated."
      else
        flash.now[:error] = "Could not update non-rewarded."
      end
      redirect_to :action => :edit
    else
      redirect_to :action => :create
    end
  end

  private

  def check_tos
    unless @partner.accepted_publisher_tos?
      if params[:terms_of_service] == '1'
        log_activity(@partner)
        @partner.update_attribute :accepted_publisher_tos, true
      else
        flash[:error] = 'You must accept the terms of service to set up non-rewarded.'
        render :new
      end
    end
  end

  def setup
    @app      = App.find(params[:app_id])
    @partner  = @app.partner
    @currency = @app.non_rewarded
  end

end
