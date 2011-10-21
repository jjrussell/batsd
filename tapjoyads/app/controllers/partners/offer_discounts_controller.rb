class Partners::OfferDiscountsController < WebsiteController
  layout 'tabbed'
  current_tab :partners

  filter_access_to :all

  before_filter :find_partner
  after_filter :save_activity_logs, :only => [ :create, :deactivate ]

  def index
    if params[:filter] == 'active'
      @offer_discounts = @partner.offer_discounts.active.paginate(:page => params[:page], :per_page => 20)
    else
      @offer_discounts = @partner.offer_discounts.paginate(:page => params[:page], :per_page => 20)
    end
  end

  def new
    @offer_discount = @partner.offer_discounts.build(:source => 'Admin')
  end

  def create
    @offer_discount = @partner.offer_discounts.build(params[:offer_discount].merge(:source => 'Admin'))
    log_activity(@offer_discount)
    if @offer_discount.save
      flash[:notice] = 'Offer discount created.'
      redirect_to partner_offer_discounts_path(@partner) and return
    else
      render :new and return
    end
  end

  def deactivate
    @offer_discount = OfferDiscount.find(params[:id])
    log_activity(@offer_discount)
    if @offer_discount.deactivate!
      flash[:notice] = 'Offer discount was deactivated.'
    else
      flash[:error] = 'Could not deactivate offer discount.'
    end
    redirect_to partner_offer_discounts_path(@partner)
  end

private

  def find_partner
    @partner = Partner.find(params[:partner_id])
  end

end
