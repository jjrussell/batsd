class InventoryManagementController < WebsiteController
  layout 'tabbed'
  current_tab :inventory_mgmt

  filter_access_to :all
  before_filter :set_partner, :get_selected_option
  before_filter :init_global_promoted_offers, :only => [:index, :global_promoted_offers]
  before_filter :init_promoted_offers, :only => [:per_app, :promoted_offers]

  def index
    @available_offers.each do |platform, offers|
      offers.map! { |offer| [offer.name, offer.id] }
    end
    @partner.global_promoted_offers.each do |promoted_offer|
      offer = promoted_offer.offer
      platform = offer.promotion_platform
      @selected_offers[platform].push(offer.id) if platform
    end
  end

  def global_promoted_offers
    promoted_offers = []
    currently_promoted = @partner.global_promoted_offers.map(&:offer_id)
    [:partner_promoted_offers_android, :partner_promoted_offers_ios, :partner_promoted_offers_wp].each do |platform|
      promoted_offers += params[platform] if params[platform].present?
    end
    promoted_offers.each do |offer_id|
      unless currently_promoted.include?(offer_id)
        flash[:error] = "Unable to save the list of promoted offers" unless GlobalPromotedOffer.new(:partner => @partner, :offer_id => offer_id).save!
      end
    end
    (currently_promoted - promoted_offers).each do |offer_id|
      promoted_offer = @partner.global_promoted_offers.find_by_offer_id(offer_id)
      promoted_offer.destroy if promoted_offer
    end
    redirect_to inventory_management_index_path
  end

  def per_app
    if @app
      @currently_promoted = @app.promoted_offers.map(&:offer_id) unless params[:commit].present?
    end
  end

  def promoted_offers
    if @app
      @currently_promoted = @app.promoted_offers.map(&:offer_id)
      if params[:promoted_offers]
        (@currently_promoted - params[:promoted_offers]).each do |offer_id|
          @app.promoted_offers.find_by_offer_id(offer_id).destroy
        end
        params[:promoted_offers].each do |offer_id|
          unless @currently_promoted.include?(offer_id)
            flash[:error] = 'Unable to save the list of promoted offers' unless PromotedOffer.new( :app => @app, :offer_id => offer_id).save!
          end
        end
        @currently_promoted = params[:promoted_offers]
      else
        @app.promoted_offers.delete_all
      end
      redirect_to :action => :per_app, :current_app => @app.id and return
    end
    redirect_to per_app_inventory_management_path
  end

  private

  def init_global_promoted_offers
    @selected_offers = { :android => [], :iphone => [], :windows => []}
    @available_offers = @partner.offers_for_promotion
  end

  def init_promoted_offers
    @global_offers = []
    @dropdown_options = { :not_for_nav => true, :submission_form => :per_app_inventory }

    if params[:current_app].present?
      @app = App.find(params[:current_app])
    end
    return unless @app

    app_platform = @app.primary_offer.promotion_platform
    return unless app_platform

    @partner.global_promoted_offers.each do |promoted_offer|
      offer = promoted_offer.offer
      @global_offers.push(offer) if offer.promotion_platform == app_platform
    end

    @available_offers = @partner.offers_for_promotion[app_platform]
    @available_offers.reject! { |promoted_offer| @global_offers.include?(promoted_offer) }
    @available_offers.map! { |offer| [offer.name, offer.id] }
  end

  def set_partner
    @partner = current_partner
  end

  def get_symbol_by_platform(prefix, platform)
    "#{prefix}#{platform}".to_sym
  end

  def get_selected_option
    @selected_state = {}
    case action_name
    when 'index'
      @selected_state[:index] = 'selected'
    when 'per_app'
      @selected_state[:per_app] = 'selected'
    end
  end
end
