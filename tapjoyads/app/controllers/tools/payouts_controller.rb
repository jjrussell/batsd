class Tools::PayoutsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create ]
  
  def index
    @partners = Partner.to_payout
  end
  
  def create
    partner = Partner.find(params[:partner_id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    amount = (params[:amount].to_f * 100).round
    payout = partner.payouts.build(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    log_activity(payout)
    render :json => { :success => payout.save }
  end

end
