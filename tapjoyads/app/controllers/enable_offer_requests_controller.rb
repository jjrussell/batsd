class EnableOfferRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    @assigned_to_me  = EnableOfferRequest.assigned_to(current_user)
    @unassigned = EnableOfferRequest.unassigned.paginate(:page => params[:page])

    @issues = {}
    (@unassigned + @assigned_to_me).each do |req|
      app = req.offer.item
      @issues[app.id] ||= []
      @issues[app.id] << {:type => 'error', :message => 'No store ID'}          if app.store_id.nil?
      @issues[app.id] << {:type => 'error', :message => 'Not integrated'}       if logins <= 0
      @issues[app.id] << {:type => 'error', :message => 'Partner Balance low'}  if app.partner.balance < 1000
      @issues[app.id] << {:type => 'warning', :message => 'Possibly iPad only'} if app.is_ipad_only?
      if app.large_download?
        message = "Large download: #{app.file_size_bytes>>20}MB"
        @issues[app.id] << {:type => 'warning', :message => message }
      end
      if app.expensive?
        message = "Expensive: $#{'%.2f' % (app.price/100.0)}"
        @issues[app.id] << {:type => 'warning', :message => message }
      end
    end
  end

  def create
    offer = Offer.find_by_id(params[:enable_offer_request][:offer_id])
    enable_request = EnableOfferRequest.new
    log_activity(enable_request)
    enable_request.offer = offer
    enable_request.requested_by = current_user
    if enable_request.save
      flash[:notice] = "Your request has been submitted."
    else
      flash[:error] = "This app #{enable_request.errors.first[1]}."
    end
    redirect_to app_offer_path(:id => offer.id, :app_id => offer.item.id)
  end

  def update
    req = EnableOfferRequest.find_by_id(params[:id])
    log_activity(req)
    log_activity(req.offer)

    case params[:do]
    when 'assign'
      if req.assign_to(current_user)
        flash[:notice] = "Assigned #{req.offer.item.name} to #{current_user.email}"
      else
        flash[:error] = "App #{req.offer.item.name} #{req.errors.first[1]}"
      end
    when 'approve'
      req.offer.tapjoy_enabled = true
      if req.offer.save
        req.approve!(true)
        flash[:notice] = "App #{req.offer.item.name} approved."
      end
    when 'reject'
      req.offer.tapjoy_enabled = false
      if req.offer.save
        req.approve!(false)
        flash[:notice] = "App #{req.offer.item.name} rejected!"
      end
    when 'unassign'
      if req.unassign
        flash[:notice] = "Unassigned from approving #{req.offer.item.name}"
      else
        flash[:error] = "App #{req.offer.item.name} #{req.errors.first[1]}"
      end
    end
    redirect_to enable_offer_requests_path
  end
end
