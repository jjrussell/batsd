class Dashboard::Tools::RankBoostsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup
  after_filter :save_activity_logs, :only => [ :create, :update, :deactivate ]

  def index
    boosts = RankBoost.includes([:offer])
    if params[:filter] == 'active' && @offer.present?
      boosts = boosts.active.where(:offer_id => @offer.id)
    elsif params[:filter] == 'active'
      boosts = boosts.active
    elsif @offer.present?
      boosts = boosts.where(:offer_id => @offer.id)
    end
    @rank_boosts = boosts.paginate(:page => params[:page], :per_page => 200)
  end

  def new
    @rank_boost = RankBoost.new
    @rank_boost.offer = @offer if @offer.present?
  end

  def create
    @rank_boost = RankBoost.new(params[:rank_boost])
    log_activity(@rank_boost)
    if @rank_boost.save
      flash[:notice] = 'Rank Boost created.'
      redirect_to statz_path(@rank_boost.offer_id)
    else
      render :new
    end
  end

  def edit
  end

  def update
    log_activity(@rank_boost)
    if @rank_boost.update_attributes(params[:rank_boost])
      flash[:notice] = 'Rank Boost updated.'
      redirect_to statz_path(@rank_boost.offer_id)
    else
      render :edit
    end
  end

  def deactivate
    log_activity(@rank_boost)
    if @rank_boost.deactivate!
      flash[:notice] = 'Rank Boost deactivated.'
    else
      flash[:error] = 'Rank Boost could not be deactivated.'
    end
    redirect_to statz_path(@rank_boost.offer_id)
  end

private

  def setup
    @rank_boost = RankBoost.find(params[:id]) if params[:id]
    if @rank_boost
      @offer = @rank_boost.offer
    elsif params[:rank_boost].present? && params[:rank_boost][:offer_id].present?
      @offer = Offer.find(params[:rank_boost][:offer_id])
    elsif params[:offer_id].present?
      @offer = Offer.find(params[:offer_id])
    else
      @offer = nil
    end
  end

end
