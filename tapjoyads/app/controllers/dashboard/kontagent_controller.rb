class Dashboard::KontagentController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :kontagent

  def index
    get_last_integration_request

    unless current_partner.kontagent_enabled
      if @kontagent_integration_request.nil? or @kontagent_integration_request.rejected?
        redirect_to :action => :new
      elsif @kontagent_integration_request.pending?
        render :show
      end
    end
  end

  def new
    @kontagent_integration_request = KontagentIntegrationRequest.new
  end

  def create
    @kontagent_integration_request             = KontagentIntegrationRequest.new(params[:kontagent_integration_request])
    @kontagent_integration_request.partner_id  = current_partner.id
    @kontagent_integration_request.user        = current_user

    if @kontagent_integration_request.no_conflicts? and @kontagent_integration_request.save!
      @last_approval = @kontagent_integration_request.approvals.order("created_at desc").limit(1).first
      render :show
    else
      redirect_to :action => :new, :error => "Sorry, but we could not create a Kontagent integration request at this time."
    end
  end

  def show
    get_last_approval
  end

  # attempt to resync current_partner with KT
  def update
    @kontagent_integration_request              = KontagentIntegrationRequest.new
    @kontagent_integration_request.partner      = current_partner
    @kontagent_integration_request.user         = current_user
    @kontagent_integration_request.subdomain    = current_partner.kontagent_subdomain
    @kontagent_integration_request.resync!

    redirect_to :action => :index
  end

  private
  def get_last_integration_request
    @kontagent_integration_request = current_partner.kontagent_integration_requests.order("created_at desc").limit(1).first
  end

  def get_last_approval
    @last_approval = get_last_integration_request.approvals.order("created_at desc").limit(1).first #last #current_partner.kontagent_integration_requests.last.approvals.last
  end
end
