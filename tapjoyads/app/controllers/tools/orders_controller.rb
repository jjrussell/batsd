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
    create_invoice = params.delete(:create_invoice)
    billing_email = order_params.delete(:billing_email)
    @order = Order.new(order_params)

    unless @order.partner
      flash[:error] = "Invalid partner id: #{@order.partner_id}"
      render :action => :new and return
    end

    @order.billing_email = billing_email unless billing_email.blank?

    log_activity(@order)
    if @order.save
      #Sqs.send_message(QueueNames::CREATE_INVOICES, @order.id) if create_invoice
      @order.create_freshbooks_invoice if create_invoice # REMOVE
      @order.save # REMOVE
      amount = sprintf("$%.2f", @order.amount / 100.0)
      flash[:notice] = "The order of <b>#{@order.amount}</b> to <b>#{@order.billing_email}</b> was successfully created."
      redirect_to new_tools_order_path
    else
      render :action => :new
    end
  end

  def failed_invoices
    @orders = Order.not_invoiced
  end

  def retry_invoicing
    order = Order.find(params[:order_id])
    order.create_freshbooks_invoice
    order.save
    if order.status != 3
      flash[:notice] = "Invoice created to billing email #{order.billing_email}"
    else
      flash[:error] = "Unable to create invoice for billing email #{order.billing_email}.  Please make sure they exist in FreshBooks."
    end
    redirect_to tools_failed_invoices_path
  end

  def mark_invoiced
    order = Order.find(params[:order_id])
    order.status = 1
    order.save
    flash[:notice] = "Order #{order.id} marked as invoiced"
    redirect_to tools_failed_invoices_path
  end

end
