class Tools::OrdersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create ]

  def new
    @order = Order.new
  end
  
  def create
    order_params = sanitize_currency_params(params[:order], [ :amount ])
    @order = Order.new(order_params)
    log_activity(@order)
    if @order.save
      dollars = @order.amount.to_s
      dollars[-2..-3] = "." if dollars.length > 1
      email = @order.partner.users.first.email rescue "(no email)"
      flash[:notice] = "The order of <b>$#{dollars}</b> to <b>#{email}</b> was successfully created."
      redirect_to new_tools_order_path
    else
      render :action => :new
    end
  end

end