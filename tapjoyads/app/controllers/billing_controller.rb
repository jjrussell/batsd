class BillingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_partner
  before_filter :get_statements, :only => [:index, :export]

  def index
    @payouts = @partner.payouts.sort
    @statements = @partner.monthly_accountings

    @current_balance = @partner.balance
    @last_payout = @payouts.last.amount
    @last_payment = @statements.map do |s|
        s.orders unless s.orders == 0
      end.compact.last # not sure what this should be
  end

  def export
    file_name = "#{@first_statement_date.strftime("%Y-%m")}_#{@last_statement_date.strftime("%Y-%m")}"
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
      # TODO: make these not fake
      @partner = Partner.find_by_id("ce059644-18a0-4f27-bc2b-c2a2d4d4e7bf")
    end

    def get_statements
      # TODO: check for begin/end dates
      @statements = @partner.monthly_accountings
      @first_statement_date= Time.parse("#{@statements.first.year}-#{@statements.first.month}-01")
      @last_statement_date = Time.parse("#{@statements.last.year}-#{@statements.last.month}-01")
    end
end
