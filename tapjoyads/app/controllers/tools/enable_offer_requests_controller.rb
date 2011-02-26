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
      
      if item.is_a? App
        @issues[item.id] << {:type => 'error', :message => 'No store ID'}          if item.store_id.nil?
        @issues[item.id] << {:type => 'warning', :message => 'Possibly iPad only'} if item.is_ipad_only?
        if item.large_download?
          message = "Large download: #{item.file_size_bytes>>20}MB"
          @issues[item.id] << {:type => 'warning', :message => message }
        end
        if req.offer.expensive?
          message = "Expensive: $#{'%.2f' % (app.price/100.0)}"
          @issues[item.id] << {:type => 'warning', :message => message }
        end
      end
        
      @issues[item.id] << {:type => 'error', :message => 'Not integrated'}       unless req.offer.integrated?
      @issues[item.id] << {:type => 'error', :message => 'Partner Balance low'}  if item.partner.balance < 1000
    end
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
    redirect_to tools_enable_offer_requests_path
  end
end
