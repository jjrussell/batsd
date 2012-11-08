class Dashboard::PartnersController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :partners



  filter_access_to :all

  before_filter :find_partner, :only => [ :show, :make_current, :manage, :update, :edit, :new_transfer, :create_transfer, :reporting, :set_tapjoy_sponsored, :new_dev_credit, :create_dev_credit]
  before_filter :get_account_managers, :only => [ :index, :managed_by, :by_country ]
  before_filter :set_platform, :only => [ :reporting ]
  after_filter :save_activity_logs, :only => [ :update, :create_transfer ]
  after_filter :flash_to_headers, :only => [:update]

  def index
    if current_user.role_symbols.include?(:agency)
      @partners = current_user.partners.order('created_at DESC').
                              includes([ :offers, :users ]).
                              paginate(:page => params[:page])
      render 'index'
      return
    end

    user_id = params.fetch(:agency_user, nil)
    manager_id = params.fetch(:managed_by, nil)
    manager_id = nil if manager_id == 'all'
    manager_id = :none if manager_id == 'none'

    @country = params.fetch(:country, nil)
    @country = nil if @country && @country.empty?
    query = params.fetch(:q, nil)
    if query
      query = query.gsub("'", '')
      query = nil if query.empty?
    end

    @partners = Partner.search(nil, manager_id, @country, query).
                        paginate(:page => params[:page])
  end

  def mail_chimp_info
    begin
      info = MailChimp.lookup_user(params[:email])
      subscribed = info["status"]=="subscribed"
      can_email = info["merges"]["CAN_EMAIL"]=="true"
    rescue
      subscribed = false
      can_email = false
    end
    render :json => { :subscribed => subscribed, :can_email => can_email }.to_json
  end

  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new
    @partner.name = params[:partner][:name]
    @partner.contact_name = params[:partner][:contact_name]
    @partner.contact_phone = params[:partner][:contact_phone]
    @partner.country = params[:partner][:country]
    @partner.users << current_user

    if @partner.save
      flash[:notice] = 'Partner successfully created.'
      redirect_to partners_path
    else
      render :action => :new
    end
  end

  def edit
  end

  def show
  end

  def update
    log_activity(@partner)

    if params[:partner].include?(:account_managers)
      account_managers = User.find_all_by_id(params[:partner][:account_managers])
      params[:partner][:account_managers] = account_managers
    end

    if params[:partner].include?(:sales_rep)
      sales_rep = User.find_all_by_email(params[:partner][:sales_rep]).first
      params[:partner][:sales_rep] = sales_rep
    end

    if params[:partner].include?(:country)
      params[:partner][:country] = params[:partner][:country].first if params[:partner][:country].is_a? Array
    end

    safe_attributes = [ :name, :developer_name, :account_managers, :account_manager_notes, :accepted_negotiated_tos,
                        :negotiated_rev_share_ends_on, :rev_share, :transfer_bonus, :disabled_partners,
                        :direct_pay_share, :approved_publisher, :billing_email, :accepted_publisher_tos,
                        :cs_contact_email, :sales_rep, :max_deduction_percentage, :discount_all_offer_types, :country ]
    safe_attributes += [ :use_server_whitelist, :enable_risk_management ] if current_user.is_admin?

    params[:partner].delete(:name) unless current_user.employee?

    name_was = @partner.name
    if @partner.safe_update_attributes(params[:partner], safe_attributes)
      if name_was != @partner.name
        TapjoyMailer.deliver_partner_name_change_notification(@partner, name_was, current_user.email, partner_url(@partner))
      end
      flash.now[:notice] = 'Partner was successfully updated.'
      render :action => :show
    else
      flash.now[:error] = 'Partner update unsuccessful.'
      render :action => :edit
    end
  end

  def manage
    if current_user.partners << @partner
      flash[:notice] = "You are now managing #{@partner.name}."
    else
      flash[:error] = 'Could not manage partner.'
    end
    redirect_to request.referer
  end

  def stop_managing
    if current_user.partners.delete(@partner)
      flash[:notice] = "You are no longer managing #{@partner.name}."
    else
      flash[:error] = 'Could not un-manage partner.'
    end
    redirect_to request.referer
  end

  def make_current
    if current_user.update_attributes({ :current_partner_id => @partner.id })
      flash[:notice] = "You are now acting as #{@partner.name}."
      partner_ids = cookies[:recent_partners].to_s.split(';')
      partner_ids.delete(@partner.id)
      partner_ids.pop if partner_ids.length >= 10
      partner_ids.unshift(@partner.id)
      session[:last_shown_app] = nil
      cookies[:recent_partners] = {
        :value => partner_ids.join(';'),
        :expires => 1.year.from_now
      }
    else
      flash[:error] = 'Could not switch partners.'
    end
    redirect_to request.referer || root_path
  end

  def new_transfer
    @freeze_enabled = PayoutFreeze.enabled?
    @transfer = Transfer.new
  end

  def create_transfer
    if PayoutFreeze.enabled?
      flash[:error] = 'Transfers are currently disabled.'
      redirect_to :action => :new_transfer
      return
    end

    transfer_params = sanitize_currency_params(params[:transfer], [:amount])
    @transfer = Transfer.new(transfer_params)

    unless @transfer.valid?
      return render :new_transfer
    end

    Partner.transaction do
      if @transfer.transfer_type.to_i == 4
        payout, order, marketing_order = @partner.build_recoupable_marketing_credit(@transfer.amount.to_i, @transfer.internal_notes)
      else
        payout, order, marketing_order = @partner.build_transfer(@transfer.amount.to_i, @transfer.internal_notes)
      end
      log_activity(payout)
      payout.save!

      log_activity(order)
      order.save!

      email = order.partner.users.first.email rescue '(no email)'
      flash[:notice] = "The transfer of <b>$#{"%.2f" % (@transfer.amount.to_i / 100.0)}</b> to <b>#{email}</b> was successfully created."

      if marketing_order.present?
        log_activity(marketing_order)
        marketing_order.save!
        flash[:notice] += "<br/>The marketing credit of <b>$#{"%.2f" % (marketing_order.amount / 100.0)}</b> to <b>#{email}</b> was successfully created."
      end
    end
    redirect_to partner_path(@partner)
  end

  def new_dev_credit
    @transfer = Transfer.new
  end

  def create_dev_credit
    transfer_params = sanitize_currency_params(params[:transfer], [:amount])
    transfer_params[:transfer_type] = transfer_params[:transfer_type].to_i
    transfer_params[:amount] = transfer_params[:amount].to_i
    @transfer = Transfer.new(transfer_params)

    unless @transfer.valid?
      render :new_dev_credit and return
    end

    Partner.transaction do
      payout = @partner.build_dev_credit(@transfer.amount, @transfer.internal_notes)
      log_activity(payout)
      payout.save!
      email = @partner.users.map(&:email).first || '(no email)'
      flash[:notice] = "The dev credit of <b>$#{"%.2f" % ((-1 * @transfer.amount) / 100.0)}</b> to <b>#{email}</b> was successfully created."
    end
    redirect_to partner_path(@partner)
  end

  def reporting
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:date], params[:end_date], params[:granularity])
    @store_options = all_android_store_options
    respond_to do |format|
      format.html do
        render 'shared/aggregate'
      end
      format.json do
        store_name = params[:store_name] if params[:store_name].present?
        options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true, :stat_prefix => get_stat_prefix('partner'), :store_name => store_name }
        @appstats = Appstats.new(@partner.id, options)
        render :json => { :data => @appstats.graph_data(:admin => true) }
      end
    end
  end

  def set_tapjoy_sponsored
    @partner.set_tapjoy_sponsored_on_offers!(params[:flag])
    flash[:notice] = "Successfully updated all offers"
    redirect_to partner_path
  end

private

  def find_partner
    @partner = Partner.find_by_id(params[:id])
    if @partner.nil?
      flash[:error] = "Could not find partner with ID: #{params[:id]}"
      redirect_to partners_path and return
    end
  end

  def get_account_managers
    @account_managers = User.account_managers.map{|u|[u.email, u.id]}.sort
    @account_managers.unshift(['All', 'all'])
    @account_managers.push(['Not assigned', 'none'])
  end

  def flash_to_headers
    return unless request.xhr?

    if flash[:error]
      response.headers['X-Message'] = flash[:error]
    elsif flash[:notice]
      response.headers['X-Message'] = flash[:notice]
    end

    flash.discard
  end
end
