class BillingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_partner
  before_filter :get_statements, :only => [:index, :export]

  def index
    @payouts = @partner.payouts.sort
    @statements = @partner.monthly_accountings

    @current_balance = @partner.balance
    @last_payout = @payouts.blank? ? 0 : @payouts.last.amount
    @last_payment = @statements.map do |s|
        s.orders unless s.orders == 0
      end.compact.last || 0
  end

  def export
    file_name = "#{@start_date.strftime("%Y-%m")}_#{@end_date.strftime("%Y-%m")}"
    response.headers['Content-Type'] = "text/csv"
    response.headers['Content-Disposition'] = "attachment; filename=statements_#{file_name}.csv"
    render :layout => false
  end

  def add_funds
  end

  def detail
    unless params[:id]
      flash[:error] = "not found"
      redirect_to billing_index_path
    end
  end

  private
    def get_partner
      @partner = current_partner
    end

    def get_statements
      @statements = @partner.monthly_accountings.sort

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

      @selected_statements = @statements.select do |s|
          @start_date <= s.to_date && s.to_date <= @end_date
        end
    end
end
