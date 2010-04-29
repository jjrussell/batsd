class ToolsController < WebsiteController
  filter_access_to [ :payouts, :create_payout ]
  
  def index
  end
  
  def payouts
    @partners = Partner.to_payout
  end
  
  def create_payout
    partner = Partner.find(params[:id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    payout = partner.payouts.build(:amount => partner.next_payout_amount, :month => cutoff_date.month, :year => cutoff_date.year);
    render :json => { :success => payout.save }
  end
  
end
