class EnableOfferRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    EnableOfferRequest.using_slave_db do
      @assigned_to_me  = EnableOfferRequest.assigned_to(current_user)
      @unassigned = EnableOfferRequest.unassigned.paginate(:page => params[:page])
    end

    @issues = {}
    options = {
      :end_time => Time.zone.now,
      :start_time => Time.zone.now.beginning_of_hour - 23.hours,
      :granularity => :daily,
      :stat_types => [ 'logins' ]
    }
    (@unassigned + @assigned_to_me).each do |req|
      app = req.offer.item
      logins = Appstats.new(app.id, options).stats['logins'].sum
      @issues[app.id] ||= []
      @issues[app.id] << {:type => 'error', :message => 'No store ID'}          if app.store_id.nil?
      @issues[app.id] << {:type => 'error', :message => 'Not integrated'}       if logins <= 0
      @issues[app.id] << {:type => 'error', :message => 'Partner Balance low'}  if app.partner.balance < 1000
      @issues[app.id] << {:type => 'error', :message => 'iPad only'}            if app.is_ipad_only?
    end
  end

  def create
    offer = Offer.find_by_id(params[:enable_offer_request][:offer_id])
    enable_request = offer.enable_offer_requests.build
    log_activity(enable_request)
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
