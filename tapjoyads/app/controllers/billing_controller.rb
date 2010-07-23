class BillingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_partner

  def index
    @payouts = @partner.payouts.sort
    @statements = @partner.monthly_accountings

    @current_balance = @partner.balance
    @last_payout = @payouts.last.amount
    @last_payment = 0
  end

  def add_funds
  end

  def detail
    unless params[:id]
      flash[:error] = "not found"
      redirect_to billing_index_path
    end
  end

  def get_partner
    # TODO: make these not fake
    @partner = Partner.find_by_id("ce059644-18a0-4f27-bc2b-c2a2d4d4e7bf")
  end
end
