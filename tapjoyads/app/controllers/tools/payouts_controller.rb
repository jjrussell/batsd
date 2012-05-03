class Tools::PayoutsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :load_payouts_list, :only => [ :index, :export ]
  after_filter :save_activity_logs, :only => [ :create, :confirm_payouts ]


  def index
    @partners = @partners.paginate(:page => params[:page])
    @freeze_enabled = PayoutFreeze.enabled?
  end

  def create
    partner = Partner.find(params[:partner_id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    amount = (params[:amount].to_f * 100).round
    payout = partner.payouts.build(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    log_activity(payout)
    if (payout_saved = payout.save)
      log_activity(partner)
      payout_threshold = payout.amount * 1.2
      partner.payout_threshold = payout_threshold > 50_000_00 ? payout_threshold : 50_000_00
      partner.save
    end
    render :json => { :success => payout_saved }
  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.toggle_confirmed_for_payout(current_user)
    render :json => { :success => partner.save!, :was_confirmed => partner.completed_payout_info? }
  end

  def export
    data = [
      'Partner_Name,Partner_id,Pending_Earnings,Cutoff_Date,Payout_Amount,' <<
      'Current_Payout_Created,Payout_Method,Account_Manager_Email,' <<
      'Confirmed,Notes'
    ]
    @partners.each do |partner|
      confirmation_notes = partner.confirmation_notes
      confirmation_notes << 'Payout Info not present' unless partner.payout_info.present? && partner.payout_info.valid?
      line = [
          partner.name.gsub(/[,]/,' '),
          partner.id.gsub(/[,]/,' '),
          NumberHelper.number_to_currency((partner.pending_earnings / 100.0), :delimiter => ''),
          (partner.payout_cutoff_date - 1.day).to_s(:yyyy_mm_dd),
          NumberHelper.number_to_currency((partner.pending_earnings / 100.0 - partner.next_payout_amount / 100.0), :delimiter => ''),
          NumberHelper.number_to_currency((partner.next_payout_amount / 100.0), :delimiter => ''),
          partner.payout_info.present? && partner.payout_info.valid? ? partner.payout_info.payout_method : '',
          partner.account_managers.present? ? (partner.account_managers.first.email) : '',
          partner.confirmed_for_payout? ? 'Confirmed' : 'Unconfirmed',
          confirmation_notes.present? ? confirmation_notes.join(';').gsub(/[,]/, '_') : ''
        ]
      data << line.join(',')
    end
    send_data(data.join("\n"), :type => 'text/csv', :filename => 'Payouts.csv')
  end

  private
  def load_payouts_list
    if params[:year] && params[:month]
      @start_date = Time.zone.parse("#{params[:year]}-#{params[:month]}-01")
      @end_date = @start_date + 1.month
      @partners = Partner.to_payout.payout_info_changed(@start_date, @end_date)
    else
      @partners = Partner.to_payout
    end

    @partners = @partners.all(:include => [:payout_info, {:users => [:user_roles]}])
  end
end
