class PartnersController < WebsiteController
  layout 'tabbed'

  current_tab :partners

  filter_access_to :all

  before_filter :find_partner, :only => [ :show, :make_current, :manage, :update ]
  before_filter :get_account_managers, :only => [ :index, :managed_by ]

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
    user = User.find_by_id(params[:id], :include => [ :partners ])
    @partners = user.partners.scoped(:order => 'created_at DESC', :include => [ :offers, :users ]).paginate(:page => params[:page])
    render 'index'
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
    users = User.find_all_by_id(params[:partner][:account_managers])
    @partner.account_managers = users
    if @partner.save
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
      redirect_to partners_path
    end
  end

  def get_account_managers
    @account_managers = User.account_managers.map{|u|[u.email, u.id]}.sort.unshift(["All", ""])
  end
end
