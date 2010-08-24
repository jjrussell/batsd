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
    setup_export_headers("tapjoy_statements_#{@start_date.strftime("%Y-%m")}_#{@end_date.strftime("%Y-%m")}")
    render :layout => false
  end

  def export_orders
    @orders = @orders.select do |o|
      @start_date.to_time <= o.created_at && o.created_at < @end_date.to_time.end_of_month
    end.sort
    
    setup_export_headers("tapjoy_payments_#{@start_date.strftime("%Y-%m")}_#{@end_date.strftime("%Y-%m")}")
    render :layout => false
  end
  
  def export_payouts
    @payouts = @payouts.select do |p|
      @start_date.to_time <= p.created_at && p.created_at < @end_date.to_time.end_of_month
    end.sort
    setup_export_headers("tapjoy_payouts_#{@start_date.strftime("%Y-%m")}_#{@end_date.strftime("%Y-%m")}")
    render :layout => false
  end

  def add_funds
  end

private
  def get_statements
    @statements = current_partner.monthly_accountings.sort
    @payouts = current_partner.payouts
    @orders = current_partner.orders

    unless @statements.blank?
      @start_date =
        if params[:billing] && params[:billing][:start_date]
          Date.parse(params[:billing][:start_date])
        else
          @statements.first.to_date
        end

      @end_date =
        if params[:billing] && params[:billing][:end_date]
          Date.parse(params[:billing][:end_date])
        else
          @statements.last.to_date
        end
    end

    @statements = @statements.select do |s|
      @start_date <= s.to_date && s.to_date <= @end_date
    end
  end
  
  def setup_export_headers(filename)
    response.headers['Content-Type'] = "text/csv"
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
  end
end
