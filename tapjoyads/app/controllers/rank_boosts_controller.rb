class RankBoostsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  
  before_filter :setup

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
    if @rank_boost.save
      flash[:success] = 'Rank Boost created.'
      redirect_to rank_boosts_path and return
    else
      render :new
    end
  end
  
  def edit
    
  end
  
  def update
    if @rank_boost.update_attributes(params[:rank_boost])
      flash[:success] = 'Rank Boost updated.'
      redirect_to rank_boosts_path and return
    else
      render :edit
    end
  end
  
  def destroy
    @rank_boost.destroy
    redirect_to rank_boosts_path and return
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
