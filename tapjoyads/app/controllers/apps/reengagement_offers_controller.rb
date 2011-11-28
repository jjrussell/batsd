class Apps::ReengagementOffersController < WebsiteController
  layout 'apps'
  current_tab :apps
  before_filter :setup
  filter_access_to :all



  def index
    @reengagement_offers = @app.reengagement_offers
    if @reengagement_offers.empty?
      redirect_to new_app_reengagement_offer_path(@app, @reengagement_offer)
    end
  end

  def new
    @reengagement_offer = @app.reengagement_offers.build :partner => current_partner
  end

  def create
    reengagement_offer_params = params[:reengagement_offer].merge(:partner => current_partner)
    if reengagement_offer_params[:day_number].to_i > 1
      reengagement_offer_params.merge!(:prerequisite_offer_id => ReengagementOffer.find_by_app_id_and_day_number_and_hidden(@app.id, reengagement_offer_params[:day_number].to_i - 1, false).id)
    end
    @reengagement_offer = @app.reengagement_offers.build reengagement_offer_params
    if @reengagement_offer.save!
      redirect_to app_reengagement_offers_path(@app)
    else
      render :new
    end
  end

  def edit
  end
  
  def destroy
    # @reengagement_offer.offers.each do |offer|
    #   offer.hidden = true
    # end
    @reengagement_offer.hidden = true
    @reengagement_offer.save!
    flash[:notice] = "Removed day #{@reengagement_offer.day_number} re-engagement offer."
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

  def toggle
    if @action_offer.toggle_user_enabled
      render :json => { :success => true, :user_enabled => @action_offer.user_enabled? }
    else
      render :json => { :success => false }
    end
  end

  private

  def setup
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id])
    else
      @app = current_partner.apps.find(params[:app_id])
    end

    if params[:id]
      @reengagement_offer = @app.reengagement_offers.find(params[:id])
      @offer = @reengagement_offer.primary_offer
      log_activity(@reengagement_offer)
      #log_activity(@offer)
    end
  end


end
