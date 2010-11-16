class PreviewExperimentsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :get_experiments

  def index
  end

  def show
    @offers = Offer.get_enabled_offers(params[:id]).reject { |offer| offer.show_rate == 0 }
  end

private

  def get_experiments
    # sort experiments by id ascending
    @experiments = Experiments::EXPERIMENTS.to_a.sort! { |a, b| a[1] <=> b[1] }
  end

end