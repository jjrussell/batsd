class Tools::EarningsAdjustmentsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :create ]

  def new
    @earnings_adjustment = EarningsAdjustment.new(:partner_id => params[:partner_id])
  end

  def create
    earnings_adjustment_params = sanitize_currency_params(params[:earnings_adjustment], [ :amount ])
    @earnings_adjustment = EarningsAdjustment.new(earnings_adjustment_params)
    log_activity(@earnings_adjustment)
    if @earnings_adjustment.save
      flash[:notice] = 'Successfully created earnings adjustment.'
      redirect_to partner_path(@earnings_adjustment.partner)
    else
      render :action => :new
    end
  end

end
