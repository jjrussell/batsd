class Apps::ReengagementOffersController < WebsiteController
  ReengagementOffer

  layout 'apps'
  current_tab :apps
  before_filter :setup, :except => [ :show ]
  filter_access_to :all

  def show
  end

  def index
    @reengagement_offers = @app.reengagement_campaign
    if @reengagement_offers.blank?
      redirect_to(new_app_reengagement_offer_path(@app))
    else
      @reengagement_offer = @reengagement_offers.first
    end
  end

  def new
    campaign_length = @app.reengagement_campaign_length
    if campaign_length > 5
      flash[:info] = "Re-engagement campaigns cannot currently be longer than 5 days."
      redirect_to(app_reengagement_offers_path(@app))
    elsif campaign_length == 0
      ReengagementOffer.create(
        :app_id                 => @app.id,
        :partner                => current_partner,
        :currency_id            => @app.primary_currency.id,
        :instructions           => 'Come back each day and get rewards!',
        :reward_value           => 0,
        :day_number             => 0
      )
    end
    @reengagement_offer = ReengagementOffer.new
  end

  def create
    params[:reengagement_offer].merge!( :app => @app, :partner => current_partner )
    reengagement_offer = ReengagementOffer.create(params[:reengagement_offer])
    flash[:notice] = "Added day #{reengagement_offer.day_number} reengagement offer."
    redirect_to(app_reengagement_offers_path(@app))
  end

  def edit
  end

  def destroy
    if @reengagement_offer == @app.reengagement_campaign.last
      @reengagement_offer.remove!
      reengagement_offers = @app.reengagement_campaign
      reengagement_offers.first.remove! if reengagement_offers.length == 1 && reengagement_offers.first.day_number == 0
      flash[:notice] = "Removed day #{@reengagement_offer.day_number} re-engagement offer."
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
    flash[:notice] = "Updated day #{@reengagement_offer.day_number} re-engagement offer."
    redirect_to(app_reengagement_offers_path(@app))
  end

  private

  def setup
    if  params[:app_id].present?
      if permitted_to?(:edit, :statz)
        @app = App.find(params[:app_id])
      else
        @app = current_partner.apps.find(params[:app_id])
      end
    end

    if params[:id]
      @reengagement_offer = @app.reengagement_campaign.find(params[:id])
      @offer = @reengagement_offer.primary_offer
    end
  end

end
