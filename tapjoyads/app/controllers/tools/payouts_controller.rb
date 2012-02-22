class Tools::PayoutsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :load_payouts_list, :only => [ :index, :export ]
  after_filter :save_activity_logs, :only => [ :create, :confirm_payouts ]

  def index
    @freeze_enabled = PayoutFreeze.enabled?
  end

  def info
    payout_info = PayoutInfo.find(params[:id])
    respond_to do |format|
      format.json { render :json => payout_info.decrypted_payment_details }
    end
  end

  def create
    partner = Partner.find(params[:partner_id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    amount = (params[:amount].to_f * 100).round
    payout = partner.payouts.build(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    log_activity(payout)
    render :json => { :success => payout.save }
  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.confirmed_for_payout = !partner.confirmed_for_payout
    partner.payout_confirmation_notes = nil if partner.confirmed_for_payout
    render :json => { :success => partner.save, :was_confirmed => partner.confirmed_for_payout}
  end

  def export
    data = [
      "Partner_Name,Partner_id,Pending_Earnings,Cutoff_Date,Payout_Amount," <<
      "Current_Payout_Created," <<
      "Confirmed,Notes,Account_Manager_Email"
    ]
    @partners.each do |partner|
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
    send_data(data.join("\n"), :type => 'text/csv', :filename =>
      "Payouts.csv")
  end

  private
  def load_payouts_list
    if params[:year] && params[:month]
      @start_date = Time.zone.parse("#{params[:year]}-#{params[:month]}-01")
      @end_date = @start_date + 1.month
      @partners = Partner.to_payout(:include => 'payout_info').payout_info_changed(@start_date, @end_date)
    else
      @partners = Partner.to_payout(:include => 'payout_info')
    end
  end

end
