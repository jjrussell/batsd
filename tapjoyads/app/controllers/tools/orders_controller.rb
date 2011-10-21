class Tools::OrdersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create ]

  def new
    @partner = Partner.find(params[:partner_id])
    @order = Order.new
  end

  def create
    order_params = sanitize_currency_params(params[:order], [ :amount ])
    billing_email = params.delete(:billing_email)
    @order = Order.new(order_params)

    @partner = @order.partner
    unless billing_email.blank?
      log_activity(@partner)
      @partner.billing_email = billing_email
      unless @partner.save
        flash[:error] = "There was a problem updating the partner: #{@partner.errors.full_messages.join(', ')}"
        render :action => :new
        return
      end
    end

    log_activity(@order)
    if @order.save
      Sqs.send_message(QueueNames::CREATE_INVOICES, @order.id) if @order.billable?
      amount = NumberHelper.new.number_to_currency(@order.amount / 100.0 )
      flash[:notice] = "The order of <b>#{amount}</b> to <b>#{@order.billing_email}</b> was successfully created."
      redirect_to new_tools_order_path(:partner_id => @partner.id)
    else
      render :action => :new
    end
  end

  def failed_invoices
    @orders = Order.not_invoiced
  end

  def retry_invoicing
    order = Order.find(params[:id])
    begin
      order.create_freshbooks_invoice!
    rescue Exception => ex
      flash[:error] = "There was a problem creating the invoice: #{ex.message}"
      redirect_to failed_invoices_tools_orders_path
    end

    if order.status == 1
      flash[:notice] = "Invoice created to billing email #{order.billing_email}"
    else
      flash[:error] = "Unable to create invoice for billing email #{order.billing_email}.  Please make sure they exist in FreshBooks."
    end
    redirect_to failed_invoices_tools_orders_path
  end

  def mark_invoiced
    order = Order.find(params[:id])
    order.status = 1
    if order.save
      flash[:notice] = "Order #{order.id} marked as invoiced"
    else
      flash[:error] = "There was a problem saving the order: #{order.errors.full_messages}"
    end
    redirect_to failed_invoices_tools_orders_path
  end

end
