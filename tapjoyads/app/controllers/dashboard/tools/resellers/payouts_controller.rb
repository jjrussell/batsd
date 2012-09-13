class Dashboard::Tools::Resellers::PayoutsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :load_payouts_list, :only => [ :index ]

  def index
    @freeze_enabled = PayoutFreeze.enabled?
  end

  def create
    success = false
    @reseller = Reseller.find(params[:reseller_id])

    Partner.transaction do
      begin
        @reseller.partners.with_next_payout.each do |partner|
          payout = partner.make_payout(partner.next_payout_amount / 100.0)
          log_activity(payout)
          log_activity(partner)
        end
        success = true
      rescue ActiveRecord::RecordInvalid => e
        ::Rails.logger.error "Could not create payout: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    render :json => { :success => success }
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
