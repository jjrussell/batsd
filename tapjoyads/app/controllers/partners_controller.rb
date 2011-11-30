class PartnersController < WebsiteController
  layout 'tabbed'

  current_tab :partners

  filter_access_to :all

  before_filter :find_partner, :only => [ :show, :make_current, :manage, :update, :edit, :new_transfer, :create_transfer, :reporting ]
  before_filter :get_account_managers, :only => [ :index, :managed_by ]
  before_filter :set_platform, :only => [ :reporting ]
  after_filter :save_activity_logs, :only => [ :update, :create_transfer ]

  def index
    if current_user.role_symbols.include?(:agency)
      @partners = current_user.partners.scoped(:order => 'created_at DESC', :include => [ :offers, :users ]).paginate(:page => params[:page])
    elsif params[:q]
      query = params[:q].gsub("'", '')
      @partners = Partner.search(query).scoped(:include => [ :offers, :users ]).paginate(:page => params[:page]).uniq
    else
      @partners = Partner.scoped(:order => 'created_at DESC', :include => [ :offers, :users ]).paginate(:page => params[:page])
    end
  end

  def managed_by
    if params[:id] == 'none'
      @partners = Partner.scoped(:order => 'created_at DESC', :include => [ :offers, :users ]).paginate(:page => params[:page]).reject do |partner|
        partner.account_managers.present?
      end
    else
      user = User.find_by_id(params[:id], :include => [ :partners ])
      @partners = user.partners.scoped(:order => 'created_at DESC', :include => [ :offers, :users ]).paginate(:page => params[:page])
    end
    render 'index'
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

    negotiated_expire_date = params[:partner][:negotiated_rev_share_ends_on].strip
    new_expiration = nil

    if params[:partner][:negotiated_rev_share] == '1'
      if negotiated_expire_date.empty?
        flash.now[:error] = 'An expiry date must be specified for partners with negotiated rev shares.'
        render :action => :edit and return
      end
      new_expiration = Date.strptime(negotiated_expire_date, '%m-%d-%Y')
      if new_expiration < DateTime.now
        flash.now[:error] = 'You can not choose a date in the past for negotiated rev share expiration time.'
        render :action => :edit and return
      end
    end

    @partner.negotiated_rev_share_ends_on = new_expiration

    safe_attributes = [ :name, :account_managers, :account_manager_notes, :accepted_negotiated_tos, :rev_share, :transfer_bonus, :disabled_partners, :direct_pay_share, :approved_publisher, :billing_email, :accepted_publisher_tos, :sales_rep, :max_deduction_percentage ]
    name_was = @partner.name
    params[:partner].delete(:negotiated_rev_share_ends_on)
    params[:partner].delete(:negotiated_rev_share)
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
      cookies[:recent_partners] = {
        :value => partner_ids.join(';'),
        :expires => 1.year.from_now
      }
    else
      flash[:error] = 'Could not switch partners.'
    end
    redirect_to request.referer
  end

  def new_transfer
  end

  def create_transfer
    sanitized_params = sanitize_currency_params(params, [ :transfer_amount ])
    amount = sanitized_params[:transfer_amount].to_i
    Partner.transaction do
      payout, order, marketing_order = @partner.build_transfer(amount)

      log_activity(payout)
      payout.save!

      log_activity(order)
      order.save!

      email = order.partner.users.first.email rescue "(no email)"
      flash[:notice] = "The transfer of <b>$#{"%.2f" % (amount / 100.0)}</b> to <b>#{email}</b> was successfully created."

      if marketing_order.present?
        log_activity(marketing_order)
        marketing_order.save!
        flash[:notice] += "<br/>The marketing credit of <b>$#{"%.2f" % (marketing_order.amount / 100.0)}</b> to <b>#{email}</b> was successfully created."
      end
    end
    redirect_to partner_path(@partner)
  end

  def reporting
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:date], params[:end_date], params[:granularity])
    respond_to do |format|
      format.html do
        render 'shared/aggregate'
      end
      format.json do
        options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true, :stat_prefix => get_stat_prefix('partner') }
        @appstats = Appstats.new(@partner.id, options)
        render :json => { :data => @appstats.graph_data(:admin => true) }
      end
    end
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
    @account_managers.unshift(["All", "all"])
    @account_managers.push(["Not assigned", "none"])
  end
end
