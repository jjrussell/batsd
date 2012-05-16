class Dashboard::Tools::PartnerChangesController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :check_completed, :only => [ :destroy, :complete ]
  after_filter :save_activity_logs, :only => [ :create, :destroy, :complete ]

  def index
    @partner_changes = PartnerChange.for_dashboard.paginate(:page => params[:page])
  end

  def new
    @partner_change = PartnerChange.new
  end

  def create
    @partner_change = PartnerChange.new(params[:partner_change])
    @partner_change.source_partner_id = @partner_change.item.partner_id
    log_activity(@partner_change)

    if @partner_change.save
      flash[:notice] = 'Change request created successfully.'
      redirect_to :action => :index
    else
      render :action => :new
    end
  end

  def destroy
    log_activity(@partner_change)
    @partner_change.destroy
    flash[:notice] = 'Change destroyed successfully.'
    redirect_to :action => :index
  end

  def complete
    log_activity(@partner_change)
    log_activity(@partner_change.item)
    @partner_change.complete!
    flash[:notice] = 'Change made successfully.'
    redirect_to :action => :index
  end

  private

  def check_completed
    @partner_change = PartnerChange.find(params[:id])
    if @partner_change.completed_at?
      flash[:error] = 'The partner change has already been completed.'
      redirect_to :action => :index
    end
  end

end
