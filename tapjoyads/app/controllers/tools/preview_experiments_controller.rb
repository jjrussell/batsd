class Tools::PreviewExperimentsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :get_experiments

  def index
  end

  def show
    if params[:id] == 'featured'
      @offers = Offer.get_cached_offers({ :type => Offer::FEATURED_OFFER_TYPE })
    elsif params[:id] == 'non_rewarded'
      @offers = Offer.get_cached_offers({ :type => Offer::NON_REWARDED_DISPLAY_OFFER_TYPE })
    else
      @offers = Offer.get_cached_offers({ :type => Offer::DEFAULT_OFFER_TYPE, :exp => params[:id] })
    end
    
    @offers.reject! { |offer| offer.show_rate == 0 }
    
    if params[:device] && params[:device] != 'all'
      @offers.reject! { |o| !o.get_device_types.include?(params[:device]) }
    end
  end

private

  def get_experiments
    # sort experiments by id ascending
    @experiments = Experiments::EXPERIMENTS.to_a.sort! { |a, b| a[1] <=> b[1] }
  end

end