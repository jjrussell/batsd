class Tools::EnableOfferRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    @assigned_to_me = EnableOfferRequest.for(current_user)
    @assigned = EnableOfferRequest.not_for(current_user).paginate(:page => params[:page])
    @unassigned = EnableOfferRequest.unassigned.paginate(:page => params[:page])

    @issues = {}
    (@unassigned + @assigned_to_me + @assigned).uniq.each do |req|
      item = req.offer.item
      @issues[item.id] ||= []

      @issues[item.id] << {:type => 'error', :message => 'Not integrated'}      unless req.offer.integrated?
      @issues[item.id] << {:type => 'error', :message => 'Partner Balance low'} unless req.offer.partner.balance >= 1000
      @issues[item.id] << {:type => 'warning', :message => 'Not user-enabled'}  unless req.offer.user_enabled?
      if req.offer.expensive?
        message = "Expensive: $#{'%.2f' % (req.offer.price / 100.0)}"
        @issues[item.id] << {:type => 'warning', :message => message}
      end

      if item.is_a? App
        @issues[item.id] << {:type => 'error', :message => 'No store ID'}          if item.store_id.nil?
        @issues[item.id] << {:type => 'warning', :message => 'Possibly iPad only'} if item.is_ipad_only?
        if item.wifi_required?
          message = "Large download: #{item.file_size_bytes>>20}MB"
          @issues[item.id] << {:type => 'warning', :message => message}
        end
      end

    end
  end

  def update
    req = EnableOfferRequest.find_by_id(params[:id])
    log_activity(req)
    log_activity(req.offer)

    case params[:do]
    when 'assign'
      if req.assign_to(current_user)
        flash[:notice] = "Assigned #{req.offer.name} to #{current_user.email}"
      else
        flash[:error] = "App #{req.offer.name} #{req.errors.first[1]}"
      end
    when 'approve'
      unless req.offer.hidden?
        req.offer.tapjoy_enabled = true
        if req.offer.save
          req.approve!(true)
          flash[:notice] = "App #{req.offer.name} approved."
        end
      else
        req.approve!(false)
        flash[:error] = "App #{req.offer.name} is an archived app. Archived apps cannot be approved."
      end
    when 'reject'
      req.offer.tapjoy_enabled = false
      if req.offer.save
        req.approve!(false)
        flash[:notice] = "App #{req.offer.name} rejected!"
      end
    when 'unassign'
      if req.unassign
        flash[:notice] = "Unassigned from approving #{req.offer.name}"
      else
        flash[:error] = "App #{req.offer.name} #{req.errors.first[1]}"
      end
    end
    redirect_to tools_enable_offer_requests_path
  end
end
