class Dashboard::Tools::SalesRepsController < Dashboard::DashboardController
  layout 'dashboard'
  current_tab :tools
  filter_access_to :all

  before_filter :get_offer

  def index
  end

  def new
    @sales_rep = SalesRep.new
    @sales_rep.start_date = Date.today
  end

  def create
    @sales_rep = SalesRep.new(params[:sales_rep])
    @sales_rep.offer = @offer
    if @sales_rep.save
      flash[:success] = "Added sales rep #{@sales_rep}"
      redirect_to tools_offer_sales_reps_path(@offer)
    else
      render :new
    end
  end

  def edit
    @sales_rep = SalesRep.find(params[:id])
    @offer = @sales_rep.offer
  end

  def update
    @sales_rep = SalesRep.find(params[:id])
    @sales_rep.update_attributes(params[:sales_rep])
    if @sales_rep.save
      flash[:success] = "Updated sales rep #{@sales_rep}"
      redirect_to tools_offer_sales_reps_path(@offer)
    else
      render :edit
    end
  end

  private

  def get_offer
    @offer = Offer.find(params[:offer_id])
  end

end
