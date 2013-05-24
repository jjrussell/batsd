class Dashboard::KontagentController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :kontagent

  def index
    get_last_integration_request

    if !current_partner.kontagent_enabled
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
    unless current_user && current_partner
      flash[:error] = "You must have an active current user and partner to continue"
      redirect_to login_path
      return
    end

    @kontagent_integration_request             = KontagentIntegrationRequest.new(params[:kontagent_integration_request])
    @kontagent_integration_request.partner_id  = current_partner.id
    @kontagent_integration_request.user        = current_user

    @accepted_terms = params[:terms_and_conditions]

    if @accepted_terms and @kontagent_integration_request.no_conflicts? and @kontagent_integration_request.save
      @last_approval = @kontagent_integration_request.approvals.order("created_at desc").limit(1).first
      flash[:notice] = "Thank you! We have successfully created your integration request."
      render :show
    else
      if @accepted_terms
        if @kontagent_integration_request.no_conflicts?
          if @kontagent_integration_request.errors
            flash[:error] = @kontagent_integration_request.errors.full_messages
          else
            flash[:error] = "We're sorry, but something went wrong attempting to register your request at this time."
          end
        else
          flash[:error] = "That domain name is already taken."
        end
      else
        flash[:error] = "You must accept Kontagent terms and conditions to register for integration."
      end
      redirect_to :action => :new
    end
  end

  def show
  end

  # attempt to resync current_partner with KT
  def resync
    kontagent_integration_request              = KontagentIntegrationRequest.new
    kontagent_integration_request.partner      = current_partner
    kontagent_integration_request.user         = current_user
    kontagent_integration_request.subdomain    = current_partner.kontagent_subdomain
    kontagent_integration_request.resync!

    # here we could set the flash based on whether the resync was successful
    # ensure we delete this request afterwards -- this integration request wasn't created by a human
    # (we should probably just invoke the sync ops manually rather than building and tearing down an integration request)
    kontagent_integration_request.delete

    redirect_to :action => :index
  end

  # action to show terms and conditions
  def terms; end

  private
  def get_last_integration_request
    requests = current_partner.try(:kontagent_integration_requests)
    if requests
      @kontagent_integration_request = requests.order("created_at desc").limit(1).first
    end
  end

  def get_last_approval
    get_last_integration_request
    if @kontagent_integration_request && !@kontagent_integration_request.nil?
      approvals = @kontagent_integration_request.try(:approvals)
      if approvals
        @last_approval = approvals.order("created_at desc").limit(1).first
      end
    end
  end
end
