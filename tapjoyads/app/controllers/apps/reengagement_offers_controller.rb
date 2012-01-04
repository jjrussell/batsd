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
    if @reengagement_offers.empty?
      redirect_to new_app_reengagement_offer_path(@app, @reengagement_offer)
    else
      @reengagement_offer = @reengagement_offers.first
    end
  end

  def new
    @reengagement_offer = @app.reengagement_offers.build :partner => current_partner
  end

  def create
    params[:reengagement_offer].merge!(:partner => current_partner)
    reengagement_offers = @app.reengagement_offers.visible
    redirect_to app_reengagement_offers_path(@app) if reengagement_offers.length >= 5
    day_number = params[:day_number].to_i
    if day_number > 1
      params.merge!(:prerequisite_offer_id => reengagement_offers[day_number - 2].id)
    end
    @reengagement_offer = @app.reengagement_offers.build params[:reengagement_offer]
    @reengagement_offer.save!
    flash[:notice] = "Added day #{@reengagement_offer.day_number} reengagement offer."
    redirect_to app_reengagement_offers_path(@app)
  end

  def edit
  end
  
  def destroy
    @reengagement_offer.hidden = true
    @reengagement_offer.save!
    flash[:notice] = "Removed day #{@reengagement_offer.day_number} re-engagement offer."
    redirect_to :action => :index, :app_id => @app.id
  end

  def update_status
    puts "======================= #{params[:enabled]}"
    if params[:app_id].present? && params[:enabled].present?
      puts "======================= #{params[:enabled]}"
      params[:enabled] == true.to_s ? ReengagementOffer.enable_all(params[:app_id]) : ReengagementOffer.disable_all(params[:app_id])
    end
    redirect_to :action => :index, :app_id => @app.id
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
