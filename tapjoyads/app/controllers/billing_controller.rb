class BillingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_statements, :only => [:index, :export_statements, :export_orders, :export_payouts]
  after_filter :save_activity_logs, :only => [ :create_order ]

  def index
    @current_balance = current_partner.balance
    @pending_earnings = current_partner.pending_earnings
    respond_to do |format|
      format.html do
        @payouts.reject!{ |p| p.is_transfer? }
        @orders.reject! { |o| o.is_transfer? || o.is_bonus? }
        @last_payout = @payouts.blank? ? 0 : @payouts.last.amount
        @last_payment = @orders.blank? ? 0 : @orders.last.amount
      end
      format.json do
        render :json => {
          :current_balance => current_partner.balance,
          :pending_earnings => current_partner.pending_earnings,
        }.to_json
      end
    end
  end

  def export_statements
    setup_export_headers("tapjoy_statements")
    render :layout => false
  end

  def export_orders
    setup_export_headers("tapjoy_payments")
    render :layout => false
  end
  
  def export_payouts
    setup_export_headers("tapjoy_payouts")
    render :layout => false
  end

  def add_funds
    @credit_card = ActiveMerchant::Billing::CreditCardWithAmount.new
  end
  
  def create_order
    cc_params = sanitize_currency_params(params[:credit_card], [ :amount ])
    @credit_card = ActiveMerchant::Billing::CreditCardWithAmount.new(cc_params)
    @order = Order.new(:partner => current_partner, :amount => @credit_card.amount, :status => 1, :payment_method => 0)
    if @credit_card.valid? && @order.valid?
      gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(:login => '6d68x2KxXVM', :password => '6fz7YyU9424pZDc6', :test => Rails.env != 'production')
      response = gateway.purchase(@credit_card.amount, @credit_card)
      if response.success?
        log_activity(@order)
        @order.payment_txn_id = response.authorization
        @order.save!
        flash[:notice] = 'Successfully added funds.'
        render :action => :receipt and return
      else
        flash[:error] = response.message
      end
    end
    render :action => :add_funds
  end

private

  def get_statements
    @payouts = current_partner.payouts.sort
    @orders = current_partner.orders.sort

    start_date = [current_partner.created_at, (@payouts.first || current_partner).created_at, (@orders.first || current_partner).created_at].min
    end_date = Time.zone.now

    @statements = {}
    date = start_date
    while date < end_date.end_of_month
      month = date.strftime("%Y-%m")
      text_month = date.strftime("%B %Y")
      @statements[month] = {:orders => [], :payouts => [], :others => [], :text_month => text_month, :start_time => date.beginning_of_month, :end_time => date.end_of_month}
      date = date.next_month
    end

    @orders.each do |order|
      if order.is_transfer? || order.is_bonus?
        month = order.created_at.strftime("%Y-%m")
        @statements[month][:others] << order
      else
        month = order.created_at.strftime("%Y-%m")
        @statements[month][:orders] << order
      end
    end

    @payouts.each do |payout|
      unless payout.is_transfer?
        month = payout.created_at.strftime("%Y-%m")
        @statements[month][:payouts] << payout
      end
    end

    @statements = @statements.sort { |a, b| a[0] <=> b[0] }
  end
  
  def setup_export_headers(filename)
    response.headers['Content-Type'] = "text/csv"
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
  end

end
