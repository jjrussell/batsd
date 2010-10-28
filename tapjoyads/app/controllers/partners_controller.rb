class PartnersController < WebsiteController
  layout 'tabbed'

  current_tab :partners

  filter_access_to :all

  before_filter :find_partner, :only => [ :show, :make_current, :manage, :update ]
  before_filter :get_account_managers, :only => [ :index, :managed_by ]
  after_filter :save_activity_logs, :only => [ :update ]

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

  def update
    params[:partner][:account_managers] = User.find_all_by_id(params[:partner][:account_managers])

    safe_attributes = [ :account_managers, :account_manager_notes ]
    if @partner.safe_update_attributes(params[:partner], safe_attributes)
      flash[:notice] = 'Partner was successfully updated.'
    else
      flash[:error] = 'Partner update unsuccessful.'
    end

    redirect_to :back
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
    if current_user.update_attribute(:current_partner_id, @partner.id)
      flash[:notice] = "You are now acting as #{@partner.name}."
    else
      flash[:error] = 'Could not switch partners.'
    end
    redirect_to request.referer
  end

private

  def find_partner
    @partner = Partner.find_by_id(params[:id])
    if @partner.nil?
      flash[:error] = "Could not find partner with ID: #{params[:id]}"
      redirect_to partners_path and return
    end

    log_activity(@partner)
  end

  def get_account_managers
    @account_managers = User.account_managers.map{|u|[u.email, u.id]}.sort
    @account_managers.unshift(["All", "all"])
    @account_managers.push(["Not assigned", "none"])
  end
end
