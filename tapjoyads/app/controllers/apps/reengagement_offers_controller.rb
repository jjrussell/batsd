class Apps::ReengagementOffersController < WebsiteController
  ReengagementOffer

  layout 'apps'
  current_tab :apps
  before_filter :setup, :except => [ :show ]
  filter_access_to :all

  def show
  end

  def index
    @reengagement_offers = ReengagementOffer.visible.find_all_by_app_id @app.id
    @reengagement_offers.blank? ? redirect_to(new_app_reengagement_offer_path(@app)) : @reengagement_offer = @reengagement_offers.first
  end

  def new
    campaign_length = ReengagementOffer.campaign_length(@app.id)
    if campaign_length > 5
      flash[:info] = "Re-engagement campaigns cannot currently be longer than 5 days."
      redirect_to app_reengagement_offers_path(@app) 
    elsif campaign_length == 0 
      ReengagementOffer.create(
        :app_id => @app.id,
        :currency_id => @app.primary_currency.id,
        :partner => current_partner,
        :instructions => 'Come back each day and get rewards!',
        :reward_value => 0,
        :day_number => 0
      )
    end
    @reengagement_offer = ReengagementOffer.new(:partner => current_partner)
  end

  def create
    reengagement_offers = ReengagementOffer.visible.find_all_by_app_id @app.id
    reengagement_offer = ReengagementOffer.new (
      :partner => current_partner,
      :app_id => params[:app_id],
      :day_number => reengagement_offers.length,
      :currency_id => params[:reengagement_offer][:currency_id],
      :reward_value => params[:reengagement_offer][:reward_value],
      :instructions => params[:reengagement_offer][:instructions],
      :prerequisite_offer_id => reengagement_offers.last.id,
      :enabled => reengagement_offers.last.enabled )
    reengagement_offer.save!
    flash[:notice] = "Added day #{reengagement_offer.day_number} reengagement offer."
    redirect_to app_reengagement_offers_path(@app)
  end

  def edit
  end
  
  def destroy
    @reengagement_offer.remove!
    reengagement_offers = @app.reengagement_offers.visible
    reengagement_offers.first.remove! if reengagement_offers.length == 1 && reengagement_offers.first.day_number == 0
    flash[:notice] = "Removed day #{@reengagement_offer.day_number} re-engagement offer."
    redirect_to app_reengagement_offers_path(@app)
  end

  def update_status
    if params[:app_id].present? && params[:enabled].present?
      params[:enabled] == '1' ? ReengagementOffer.enable_for_app!(params[:app_id]) : ReengagementOffer.disable_for_app!(params[:app_id])
    end
    redirect_to app_reengagement_offers_path(@app)
  end

  def update
    @reengagement_offer.currency_id = params[:reengagement_offer][:currency_id]
    @reengagement_offer.reward_value = params[:reengagement_offer][:reward_value]
    @reengagement_offer.instructions = params[:reengagement_offer][:instructions]
    @reengagement_offer.save!
    flash[:notice] = "Updated day #{@reengagement_offer.day_number} re-engagement offer."
    redirect_to app_reengagement_offers_path(@app)
  end

  private

  # def build_new_reengagement(options)
  #   Rails.logger.info options
  #   reengagement_offer = ReengagementOffer.new options
  #   reengagement_offers = @app.reengagement_offers.visible
  #   reengagement_offers.present? && reengagement_offers.last.enabled? ? reengagement_offer.enable! : reengagement_offer.save!
  #   reengagement_offer
  # end

  def setup
    if  params[:app_id].present?
      if permitted_to? :edit, :statz
        @app = App.find(params[:app_id])
      else
        @app = current_partner.apps.find(params[:app_id])
      end
    end

    if params[:id]
      @reengagement_offer = ReengagementOffer.find(params[:id])
      @app = App.find(@reengagement_offer.app_id) unless @app.present?
      @offer = @reengagement_offer.primary_offer
      log_activity(@reengagement_offer)
    end
  end

end
