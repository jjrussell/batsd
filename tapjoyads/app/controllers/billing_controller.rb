class BillingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_statements, :only => [:index, :export_statements, :export_orders, :export_payouts]

  def index
    @current_balance = current_partner.balance
    @last_payout = @payouts.blank? ? 0 : @payouts.last.amount
    @last_payment = @orders.blank? ? 0 : @orders.last.amount
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
  end

private
  def get_statements
    @payouts = current_partner.payouts.sort
    @orders = current_partner.orders.sort

    start_date = [@payouts.first.created_at, @orders.first.created_at].min
    end_date = Time.zone.now

    @statements = {}
    date = start_date
    while date < end_date
      month = date.strftime("%Y-%m")
      text_month = date.strftime("%B %Y")
      @statements[month] = {:orders => 0, :payouts => 0, :text_month => text_month, :start_time => date.beginning_of_month, :end_time => date.end_of_month}
      date = date.next_month
    end
    
    @orders.each do |order|
      month = order.created_at.strftime("%Y-%m")
      @statements[month][:orders] += order.amount
    end
    
    @payouts.each do |payout|
      month = payout.created_at.strftime("%Y-%m")
      @statements[month][:payouts] += payout.amount
    end
    
    @statements = @statements.sort { |a, b| a[0] <=> b[0] }
  end
  
  def setup_export_headers(filename)
    response.headers['Content-Type'] = "text/csv"
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
  end
end
