class InventoryManagementController < WebsiteController
  layout 'tabbed'
  current_tab :inventory_mgmt

  filter_access_to :all
  before_filter :set_partner, :get_selected_option

  def index
    @available_offers = @partner.offers_for_promotion
    @selected_offers = { :android => [], :ios => [], :wp => []}
    @available_offers.each do |platform, offers|
      offers.map! { |offer| [offer.name, offer.id] }
    end

    currently_promoted = @partner.global_promoted_offers.map(&:offer_id)

    if params[:commit].present?
      promoted_offers = []
      [:partner_promoted_offers_android, :partner_promoted_offers_ios, :partner_promoted_offers_wp].each do |platform|
        promoted_offers += params[platform] if params[platform].present?
      end
      promoted_offers.each do |offer_id|
        unless currently_promoted.include?(offer_id)
          flash[:error] = "Unable to save the list of promoted offers" unless GlobalPromotedOffer.new(:partner => @partner, :offer_id => offer_id).save!
        end
      end
      (currently_promoted - promoted_offers).each do |offer_id|
        promoted_offer = GlobalPromotedOffer.find_by_partner_id_and_offer_id(@partner.id, offer_id)
        GlobalPromotedOffer.delete(promoted_offer) if promoted_offer
      end
      @selected_offers[:ios] = params[:partner_promoted_offers_ios] if params[:partner_promoted_offers_ios].present?
      @selected_offers[:android] = params[:partner_promoted_offers_android] if params[:partner_promoted_offers_android].present?
      @selected_offers[:wp] = params[:partner_promoted_offers_wp] if params[:partner_promoted_offers_wp].present?
    else
      @partner.global_promoted_offers.each do |promoted_offer|
        offer = promoted_offer.offer
        platform = Offer.get_platform_symbol(offer)
        @selected_offers[platform].push(offer.id) if platform
      end
    end
  end

  def per_app
    @dropdown_options = { :not_for_nav => true, :submission_form => :per_app_inventory }
    @global_offers = []

    if params[:current_app].present?
      @app = App.find(params[:current_app])
      return unless @app

      app_platform = Offer.get_platform_symbol(@app.primary_offer)
      return unless app_platform

      @partner.global_promoted_offers.each do |promoted_offer|
        offer = promoted_offer.offer
        @global_offers.push(offer) if Offer.get_platform_symbol(offer) == app_platform
      end

      @available_offers = @partner.offers_for_promotion[app_platform]
      @available_offers.reject! { |promoted_offer| @global_offers.include?(promoted_offer) }
      @available_offers.map! { |offer| [offer.name, offer.id] }
      @currently_promoted = @app.promoted_offers.map(&:offer_id)

      if params[:commit].present?
        unless params[:promoted_offers]
          @app.promoted_offers.delete_all
          return
        end

        (@currently_promoted - params[:promoted_offers]).each do |offer_id|
          PromotedOffer.find_by_app_id_and_offer_id(@app.id, offer_id).delete
        end

        params[:promoted_offers].each do |offer_id|
          unless @currently_promoted.include?(offer_id)
            flash[:error] = 'Unable to save the list of promoted offers' unless PromotedOffer.new( :app => @app, :offer_id => offer_id).save!
          end
        end

        @currently_promoted = params[:promoted_offers]
      end
    end
  end

  private

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
