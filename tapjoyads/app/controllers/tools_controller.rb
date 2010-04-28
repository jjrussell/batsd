class ToolsController < WebsiteController
  filter_access_to [ :payouts, :create_payout ]
  
  def index
  end
  
  def payouts
    @partners = Partner.to_payout
  end
  
  def create_payout
    partner = Partner.find(params[:id])
    date = Time.zone.parse(params[:cutoff_date]) - 1.day
    payout = partner.payouts.build(:amount => params[:amount].to_i, :month => date.month, :year => date.year)
    if payout.save
      render :text => 'Complete'
    else
      render :text => 'Error'
    end
  end
  
end
