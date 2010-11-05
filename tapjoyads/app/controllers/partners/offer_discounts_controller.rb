class Partners::OfferDiscountsController < WebsiteController
  layout 'tabbed'
  current_tab :partners
  
  filter_access_to :all
  
  before_filter :find_partner
  
  def index
    @offer_discounts = @partner.offer_discounts.paginate(:page => params[:page], :per_page => 20)
  end
  
  def new
    @offer_discount = @partner.offer_discounts.build(:source => 'Admin')
  end
  
  def create
    @offer_discount = @partner.offer_discounts.build(params[:offer_discount].merge(:source => 'Admin'))
    if @offer_discount.save
      flash[:notice] = 'Offer discount created.'
      redirect_to partner_offer_discounts_path(@partner) and return
    else
      render :new and return
    end
  end
  
  def deactivate
    @offer_discount = OfferDiscount.find(params[:id])
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
