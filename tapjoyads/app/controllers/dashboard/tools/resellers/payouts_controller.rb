class Dashboard::Tools::Resellers::PayoutsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :load_payouts_list, :only => [ :index, :export ]

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

  def export
    data = [
      "Partner_Name,Partner_id,Pending_Earnings,Cutoff_Date,Payout_Amount," <<
      "Current_Payout_Created," <<
      "Confirmed,Notes,Account_Manager_Email"
    ]
    @resellers.each do |reseller|
      reseller.partners.each do |partner|
        line = [
            partner.name.gsub(/[,]/,' '),
            partner.id.gsub(/[,]/,' '),
            NumberHelper.number_to_currency((partner.pending_earnings / 100.0), :delimiter => ''),
            (partner.payout_cutoff_date - 1.day).to_s(:yyyy_mm_dd),
            NumberHelper.number_to_currency((partner.pending_earnings / 100.0 - partner.next_payout_amount / 100.0), :delimiter => ''),
            NumberHelper.number_to_currency((partner.next_payout_amount / 100.0), :delimiter => ''),
            partner.confirmed_for_payout? ? "Confirmed" : "Unconfirmed",
            partner.payout_confirmation_notes.present? ? partner.payout_confirmation_notes.gsub(/[,]/, '_') : '' ,
            partner.account_managers.present? ? (partner.account_managers.first.email) : ''
          ]
        data << line.join(',')
      end
    end
    send_data(data.join("\n"), :type => 'text/csv', :filename =>
      "Payouts.csv")
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
