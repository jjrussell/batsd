class Dashboard::ReengagementOffersController < Dashboard::DashboardController
  ReengagementOffer

  layout :resolve_layout

  current_tab :apps

  before_filter :setup

  filter_access_to :all

  DAY_0_INSTRUCTIONS = "Come back each day and get rewards!"

  def show
    verify_params([:id])
  end

  def index
    redirect_to(new_app_reengagement_offer_path(@app)) if @campaign.empty?
  end

  def new
    if @campaign.length > 5
      flash[:info] = "Daily Reward campaigns cannot currently be longer than 5 days."
      redirect_to(app_reengagement_offers_path(@app))
    elsif @campaign.length == 0
      currency = @app.primary_currency
      unless currency.try(:rewarded?) && currency.try(:tapjoy_enabled?)
        currency = @currencies.first
      end
      @app.build_reengagement_offer(
        :reward_value => 0,
        :currency     => currency,
        :instructions => DAY_0_INSTRUCTIONS
      ).save
    end
    @reengagement_offer = @app.build_reengagement_offer
  end

  def create
    @reengagement_offer = @app.build_reengagement_offer(params[:reengagement_offer])
    if @reengagement_offer.save
      flash[:notice] = "Added day #{@reengagement_offer.day_number} Daily Reward."
      redirect_to(app_reengagement_offers_path(@app))
    else
      flash[:error] = "Problems encountered while adding Daily Reward."
      render :action => :new
    end
  end

  def destroy
    if @reengagement_offer == @campaign.last
      @reengagement_offer.hide!
      @campaign.first.hide! if @campaign.length == 1 && @campaign.first.day_number == 0
      flash[:notice] = "Removed day #{@reengagement_offer.day_number} Daily Reward."
    end
    redirect_to(app_reengagement_offers_path(@app))
  end

  def update_status
    if params[:enabled]
      params[:enabled] == '1' ? @app.enable_reengagement_campaign! : @app.disable_reengagement_campaign!
    end
    redirect_to(app_reengagement_offers_path(@app))
  end

  def update
    safe_attributes = [ :currency_id, :reward_value, :instructions ]
    @reengagement_offer.safe_update_attributes(params[:reengagement_offer], safe_attributes)
    @reengagement_offer.save!
    flash[:notice] = "Updated day #{@reengagement_offer.day_number} Daily Reward."
    redirect_to(app_reengagement_offers_path(@app))
  end

  private

  def resolve_layout
    case action_name
    when 'show'
      'mobile'
    else
      'apps'
    end
  end

  def setup
    if params[:app_id].present?
      if permitted_to?(:edit, :dashboard_statz)
        @app = App.find(params[:app_id])
      else
        @app = current_partner.apps.find(params[:app_id])
      end
      @currencies = @app.currencies.select { |c| c.tapjoy_enabled? && c.rewarded?}
      render :action => :index and return false if @currencies.empty?
      @campaign = @app.reengagement_campaign
    end

    if params[:id]
      @reengagement_offer = @campaign.find(params[:id])
      @offer = @reengagement_offer.primary_offer
    end
  end

end
