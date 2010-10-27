class RankBoostsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  
  before_filter :setup
  after_filter :save_activity_logs, :only => [ :create, :update, :deactivate ]

  def index
    if params[:filter] == 'Active'
      @rank_boosts = RankBoost.active
    else
      @rank_boosts = RankBoost.all
    end
  end
  
  def new
    @rank_boost = RankBoost.new
  end
  
  def create
    @rank_boost = RankBoost.new(params[:rank_boost])
    log_activity(@rank_boost)
    if @rank_boost.save
      flash[:notice] = 'Rank Boost created.'
      redirect_to rank_boosts_path
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
      redirect_to rank_boosts_path
    else
      render :edit
    end
  end
  
  def deactivate
    log_activity(@rank_boost)
    @rank_boost.end_time = Time.zone.now
    if @rank_boost.save
      flash[:notice] = 'Rank Boost deactivated.'
    else
      flash[:error] = 'Rank Boost could not be deactivated.'
    end
    redirect_to rank_boosts_path
  end
  
private
  
  def setup
    @rank_boost = RankBoost.find(params[:id]) if params[:id]
    if @rank_boost
      @offer = @rank_boost.offer
    elsif params[:rank_boost].present? && params[:rank_boost][:offer_id].present?
      @offer = Offer.find(params[:rank_boost][:offer_id])
    else
      @offer = nil
    end
  end
  
end
