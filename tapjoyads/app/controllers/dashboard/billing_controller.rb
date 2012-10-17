class Dashboard::BillingController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :billing

  filter_access_to :all
  before_filter :get_selected_option
  before_filter :get_statements, :only => [:index, :export_statements, :export_orders, :export_payouts, :export_adjustments]
  before_filter :nag_user_about_payout_info, :except => [:payout_info]
  after_filter :save_activity_logs, :only => [ :create_order, :create_transfer, :update_payout_info ]

  def index
    @current_balance = current_partner.balance
    @pending_earnings = current_partner.pending_earnings
    respond_to do |format|
      format.html do
        @payouts.reject! { |p| p.is_transfer?  || p.is_dev_credit? || p.is_recoupable_marketing_credit? }
        @orders.reject! { |o| o.is_transfer? || o.is_bonus? || o.is_marketing_credit? || o.is_recoupable_marketing_credit? }
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
    setup_export_headers('tapjoy_statements')
    render :layout => false
  end

  def export_orders
    setup_export_headers('tapjoy_payments')
    render :layout => false
  end

  def export_payouts
    setup_export_headers('tapjoy_payouts')
    render :layout => false
  end

  def export_adjustments
    setup_export_headers('tapjoy_adjustments')
    render :layout => false
  end

  def add_funds
    @credit_card = ActiveMerchant::Billing::CreditCardWithAmount.new
    begin
      @payment_profiles = Billing.get_payment_profiles_for_select(current_user)
    rescue Exception => e
      flash.now[:error] = 'An error occurred retrieving your saved credit card information. Please reload the page to try again.'
      @payment_profiles = [ [ 'New Card', 'new_card' ] ]
    end
    @selected_profile   = @payment_profiles.first[1]
    @hideable_row_class = @selected_profile == 'new_card' ? 'hideable' : 'hideable hidden'
  end

  def create_order
    cc_params    = sanitize_currency_params(params[:credit_card], [ :amount ])
    @credit_card = ActiveMerchant::Billing::CreditCardWithAmount.new(cc_params)
    begin
      @payment_profiles = Billing.get_payment_profiles_for_select(current_user)
    rescue Exception => e
      if params[:payment_profile] == 'new_card'
        @payment_profiles = [ [ 'New Card', 'new_card' ] ]
      else
        flash[:error] = 'An error occurred retrieving your saved credit card information. Please try your transaction again.'
        redirect_to add_funds_billing_path and return
      end
    end
    @selected_profile   = params[:payment_profile]
    @hideable_row_class = @selected_profile == 'new_card' ? 'hideable' : 'hideable hidden'
    @order              = Order.new(:partner => current_partner, :amount => @credit_card.amount, :status => 1, :payment_method => 0, :note => 'Created by user from billing controller')

    if @order.valid? && ((params[:payment_profile] == 'new_card' && @credit_card.valid?) || (params[:payment_profile] != 'new_card' && @credit_card.valid_amount?))
      begin
        if params[:payment_profile] == 'new_card'
          response = Billing.charge_credit_card(@credit_card, @credit_card.amount, current_partner.id)
          @receipt_card_number = @credit_card.display_number
        else
          response = Billing.charge_payment_profile(current_user, params[:payment_profile], @credit_card.amount, current_partner.id)
          @receipt_card_number = @payment_profiles.find { |pp| pp[1] == params[:payment_profile] }[0]
        end
      rescue Exception => e
        flash.now[:error] = 'Unable to charge card. Please try your transaction again.'
        render :action => :add_funds and return
      end

      if response.success?
        log_activity(@order)
        @order.payment_txn_id = response.params['transaction_id']
        @order.save!
        flash.now[:notice] = 'Successfully added funds.'

        if params[:save_card] == '1' && params[:payment_profile] == 'new_card'
          begin
            Billing.create_customer_profile(current_user)
            Billing.create_payment_profile(current_user, @credit_card)
          rescue ActiveMerchant::ConnectionError => e
            # do nothing, the card just wont be saved
          end
        end

        render :action => :receipt and return
      else
        flash.now[:error] = response.message
      end
    end

    render :action => :add_funds
  end

  def forget_credit_card
    begin
      raise unless Billing.delete_payment_profile(current_user, params[:payment_profile_id]) == Billing::SUCCESS_MSG
    rescue Exception => e
      flash[:error] = 'An error occurred deleting your saved credit card information. Please contact <a href="mailto:support@tapjoy.com">support@tapjoy.com</a>.'
    end
    redirect_to add_funds_billing_path
  end

  def transfer_funds
    @freeze_enabled = PayoutFreeze.enabled?
  end

  def create_transfer
    if PayoutFreeze.enabled?
      flash[:error] = 'Transfers are currently disabled.'
      redirect_to :action => :transfer_funds
      return
    end

    amount = sanitize_currency_param(params[ :transfer_amount ]).to_i
    if amount <= 0
      flash[:error] = 'Transfer amount must be more than $0.'
    elsif amount > current_partner.pending_earnings
      flash[:error] = 'Transfer amount must be less than your Pending Earnings.'
    else
      Partner.transaction do
        payout, order, marketing_order = current_partner.build_transfer(amount, 'Submitted by partner.')

        log_activity(payout)
        payout.save!

        log_activity(order)
        order.save!

        flash[:notice] = "Successfully transferred #{params[:transfer_amount]}"
        if marketing_order.present?
          log_activity(marketing_order)
          marketing_order.save!
          flash[:notice] += " and $#{"%.2f" % (marketing_order.amount / 100.0)}</b> transfer bonus."
        end
      end
    end
    redirect_to transfer_funds_billing_path
  end

  def payout_info
  end

  def update_payout_info
    @payout_info = current_partner.payout_info || current_partner.build_payout_info
    log_activity(@payout_info)

    safe_attributes = [
      :beneficiary_name, :company_name, :doing_business_as,
      :tax_country, :account_type, :billing_name, :tax_id, :signature, :terms,
      :address_country, :address_1, :address_2, :address_city, :address_state, :address_postal_code,
      :payout_method, :bank_name, :bank_address, :bank_account_number, :bank_routing_number,
      :payment_country, :paypal_email
    ]

    unless current_user.employee? || @payout_info.new_record?
      [:billing_name, :beneficiary_name, :tax_id].each { |field| params[:payout_info].delete(field) }
    end

    if @payout_info.safe_update_attributes(params[:payout_info], safe_attributes)
      log_activity(current_partner)
      current_partner.payout_info_confirmation = false
      current_partner.save
      flash[:notice] = 'Your information has been saved.'
      redirect_to payout_info_billing_path
    else
      if !@payout_info.valid?
        flash.now[:error] = 'Please complete all fields to save.'
      else
        flash.now[:error] = @payout_info.errors.map do |error|
          [error[0].humanize, error[1]].join(' ')
        end.join('. ')
      end
      render :action => :payout_info
    end
  end

private

  def get_statements
    @payouts = current_partner.payouts.sort
    @orders = current_partner.orders.sort
    @adjustments = current_partner.earnings_adjustments.sort

    start_date = [current_partner.created_at, (@payouts.first || current_partner).created_at, (@orders.first || current_partner).created_at, (@adjustments.first || current_partner).created_at].min
    end_date = Time.zone.now

    @statements = {}
    date = start_date
    while date < end_date.end_of_month
      month = date.strftime("%Y-%m")
      text_month = date.strftime("%B %Y")
      @statements[month] = {:orders => [], :payouts => [], :others => [], :adjustments => [], :dev_credits => [], :text_month => text_month, :start_time => date.beginning_of_month, :end_time => date.end_of_month}
      date = date.next_month
    end

    @orders.each do |order|
      if order.is_transfer? || order.is_bonus? || order.is_marketing_credit? || order.is_recoupable_marketing_credit?
        month = order.created_at.strftime("%Y-%m")
        @statements[month][:others] << order
      else
        month = order.created_at.strftime("%Y-%m")
        @statements[month][:orders] << order
      end
    end

    @payouts.each do |payout|
      unless payout.is_transfer? || payout.is_recoupable_marketing_credit?
        month = payout.created_at.strftime("%Y-%m")
        if payout.is_dev_credit?
          @statements[month][:dev_credits] << payout
        else
          @statements[month][:payouts] << payout
        end
      end
    end

    @adjustments.each do |adjustment|
      month = adjustment.created_at.strftime("%Y-%m")
      @statements[month][:adjustments] << adjustment
    end

    @statements = @statements.sort { |a, b| a[0] <=> b[0] }
  end

  def setup_export_headers(filename)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
  end

  def get_selected_option
    @selected_state = {}
    case action_name
    when 'index'
      @selected_state[:index] = 'selected'
    when /add_funds|create_order/
      @selected_state[:add_funds] = 'selected'
    when 'transfer_funds'
      @selected_state[:transfer_funds] = 'selected'
    when 'payout_info'
      @selected_state[:payout_info] = 'selected'
    end
  end
end
