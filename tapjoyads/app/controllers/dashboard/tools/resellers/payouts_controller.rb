class Dashboard::Tools::Resellers::PayoutsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :load_payouts_list, :only => [ :index ]

  def index
    @freeze_enabled = PayoutFreeze.enabled?
  end

  def create
    failed_payouts = []
    @reseller = Reseller.find(params[:reseller_id])

    @reseller.partners.each do |partner|
      payout = partner.make_payout(partner.next_payout_amount / 100.0)
      failed_payouts << partner.name unless payout.persisted?

      log_activity(payout)
      log_activity(partner) if payout.persisted?
    end

    render :json => { :success => failed_payouts.empty? }
  end

  private
  def load_payouts_list
    if params[:year] && params[:month]
      @start_date = Time.zone.parse("#{params[:year]}-#{params[:month]}-01")
      @end_date = @start_date + 1.month
      @resellers = Reseller.to_payout.payout_info_changed(@start_date, @end_date)
    else
      @resellers = Reseller.to_payout
    end
  end

end
