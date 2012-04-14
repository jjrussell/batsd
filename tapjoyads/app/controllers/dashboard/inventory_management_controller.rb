class Dashboard::InventoryManagementController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :inventory

  filter_access_to :all
  before_filter :get_selected_option
  before_filter :init_partner_promoted_offers, :only => [:index, :partner_promoted_offers]
  before_filter :init_promoted_offers, :only => [:per_app, :promoted_offers]

  def index
    @available_offers.each do |platform, offers|
      offers.map! { |offer| [offer.name, offer.id] }
    end
  end

  def partner_promoted_offers
    promoted_offers = []
    [:partner_promoted_offers_android, :partner_promoted_offers_ios, :partner_promoted_offers_wp].each do |platform|
      promoted_offers += params[platform] if params[platform].present?
    end

    flash[:error] = "Unable to save the list of promoted offers" unless current_partner.update_promoted_offers(promoted_offers)
    redirect_to inventory_management_index_path
  end

  def per_app
  end

  def promoted_offers
    if @app
      flash[:error] = "Unable to save the list of promoted offers" unless @app.update_promoted_offers(params[:promoted_offers] || [])
    end
    redirect_to per_app_inventory_management_path(@app ? { :current_app => @app.id } : nil)
  end

  private

  def init_partner_promoted_offers
    @selected_offers = current_partner.get_promoted_offers
    @available_offers = current_partner.offers_for_promotion
  end

  def init_promoted_offers
    @global_offers = []
    @dropdown_options = { :not_for_nav => true, :with_new_app_button => false }

    if params[:current_app].present?
      @app = App.find(params[:current_app])
    end
    return unless @app && @app.primary_currency

    @currently_promoted = @app.primary_currency.get_promoted_offers

    app_platform = @app.platform.to_sym
    return unless app_platform

    current_partner.get_promoted_offers.each do |promoted_offer|
      offer = Offer.find(promoted_offer)
      @global_offers.push(offer) if offer.promotion_platform == app_platform
    end

    @available_offers = current_partner.offers_for_promotion[app_platform]
    @available_offers.reject! { |promoted_offer| @global_offers.include?(promoted_offer) }
    @available_offers.map! { |offer| [offer.name, offer.id] }
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
