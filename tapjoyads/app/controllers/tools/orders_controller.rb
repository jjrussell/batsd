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
    billing_email = order_params.delete(:billing_email)
    @order = Order.new(order_params)

    unless @order.partner
      flash[:error] = "Invalid partner id: #{@order.partner_id}"
      render :action => :new and return
    end

    unless billing_email.blank?
      partner = @order.partner
      partner.billing_email = billing_email
      partner.save
    end

    log_activity(@order)
    if @order.save
      Sqs.send_message(QueueNames::CREATE_INVOICES, @order.id) if @order.create_invoice
      amount = NumberHelper.new.number_to_currency(@order.amount / 100.0 )
      flash[:notice] = "The order of <b>#{amount}</b> to <b>#{@order.billing_email}</b> was successfully created."
      redirect_to new_tools_order_path
    else
      render :action => :new
    end
  end

  def failed_invoices
    @orders = Order.not_invoiced
  end

  def retry_invoicing
    order = Order.find(params[:id])
    order.create_freshbooks_invoice
    order.save
    if order.status != 0
      flash[:notice] = "Invoice created to billing email #{order.billing_email}"
    else
      flash[:error] = "Unable to create invoice for billing email #{order.billing_email}.  Please make sure they exist in FreshBooks."
    end
    redirect_to failed_invoices_tools_orders_path
  end

  def mark_invoiced
    order = Order.find(params[:id])
    order.status = 1
    order.save
    flash[:notice] = "Order #{order.id} marked as invoiced"
    redirect_to failed_invoices_tools_orders_path
  end

end
