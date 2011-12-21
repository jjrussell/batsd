class Tools::StaffPicksController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  
  # helper_method :all_apps
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    now = Time.zone.now
    if params[:offer_type]
      @active_staff_picks   = StaffPick.active(now).for_offer_type(params[:offer_type]).ordered_by_date.paginate(:page => params[:active_page], :per_page => 20)
      @upcoming_staff_picks = StaffPick.upcoming(now).for_offer_type(params[:offer_type]).ordered_by_date.paginate(:page => params[:upcoming_page], :per_page => 10)
      @expired_staff_picks  = StaffPick.expired(now).for_offer_type(params[:offer_type]).ordered_by_date.paginate(:page => params[:expired_page], :per_page => 2)
    else
      @active_staff_picks   = StaffPick.active(now).ordered_by_date.paginate(:page => params[:active_page], :per_page => 20)
      @upcoming_staff_picks = StaffPick.upcoming(now).ordered_by_date.paginate(:page => params[:upcoming_page], :per_page => 10)
      @expired_staff_picks  = StaffPick.expired(now).ordered_by_date.paginate(:page => params[:expired_page], :per_page => 2)
    end
  end

  def new
    @staff_pick = StaffPick.new
    @employees = Employee.active_by_first_name
  end

  def create
    @staff_pick = StaffPick.new(params[:staff_pick])
    @staff_pick.author = Employee.find_by_id(params[:staff_pick][:author_id]) if params[:staff_pick][:author_id].present?
    @staff_pick.offer = Offer.find_by_id(params[:staff_pick][:offer_id]) if params[:staff_pick][:offer_id].present?
    
    params[:staff_pick][:main_icon_url] = @staff_pick.author.get_photo_url(:source => :cloudfront) unless params[:staff_pick][:offer_type] == 'App Promo (FAAD)'

    unless date_validate?
      setup_before_render('End Date must be equal to or greater than Start Date.')
      render :action => :new
      return
    end

    unless platforms_validate?
      setup_before_render("Please include [#{Offer::APPLE_DEVICES.join(", ")}] for iOS platform.")
      render :action => :new
      return
    end

    if @staff_pick.save
      @staff_pick.save_icon!(params[:main_icon].read, "#{@staff_pick.id}_main")  if params[:main_icon].present?
      @staff_pick.save_icon!(params[:secondary_icon].read, "#{@staff_pick.id}_secondary") if params[:secondary_icon].present?
      flash[:notice] = 'Staff pick was successfully created.'
      redirect_to tools_staff_picks_path
    else
      setup_before_render('Cannot update, try again.')
      render :action => :new
    end
  end

  def edit
    @staff_pick = StaffPick.find(params[:id])
    @employees = Employee.active_by_first_name
    @search_result_name = Offer.find_by_id(@staff_pick.offer_id).search_result_name if @staff_pick.offer_id.present?
  end

  def update
    @staff_pick = StaffPick.find(params[:id])
    @staff_pick.author = Employee.find_by_id(params[:staff_pick][:author_id]) if params[:staff_pick][:author_id].present?
    @staff_pick.offer = Offer.find_by_id(params[:staff_pick][:offer_id]) if params[:staff_pick][:offer_id].present?
    
    params[:staff_pick][:main_icon_url] = @staff_pick.author.get_photo_url(:source => :cloudfront) unless params[:staff_pick][:offer_type] == 'App Promo (FAAD)'
    
    Rails.logger.info("===================>>>>>>#{params[:staff_pick][:secondary_icon_url]}")
    Rails.logger.info("===================>>>>>>#{params[:staff_pick][:secondary_icon].present?}")
    
    unless date_validate?
      setup_before_render('End Date must be equal to or greater than Start Date.')
      render :action => :edit, :id => params[:id]
      return
    end

    unless platforms_validate?
      setup_before_render("Please include [#{Offer::APPLE_DEVICES.join(", ")}] for iOS platform.")
      render :action => :edit, :id => params[:id]
      return
    end

    if @staff_pick.update_attributes(params[:staff_pick])
      @staff_pick.save_icon!(params[:main_icon].read, "#{@staff_pick.id}_main")  if params[:main_icon].present?
      @staff_pick.save_icon!(params[:secondary_icon].read, "#{@staff_pick.id}_secondary") if params[:secondary_icon].present?
      flash[:notice] = 'Staff pick was successfully updated.'
      redirect_to tools_staff_picks_path
    else
      setup_before_render('Cannot update, try again.')
      render :action => :edit
    end
  end

  def destroy
    StaffPick.find(params[:id]).destroy
    redirect_to tools_staff_picks_path
  end

  private

  def setup_before_render(error_msg)
    flash.now[:error] = error_msg
    @employees = Employee.active_by_first_name
    @search_result_name = Offer.find_by_id(params[:staff_pick][:offer_id]).search_result_name if params[:staff_pick][:offer_id].present? #@staff_pick.app_id.present?
  end

  def date_validate?
    Date.parse(params[:staff_pick][:end_date]) >= Date.parse(params[:staff_pick][:start_date])
  end

  def platforms_validate?
    union = params[:staff_pick][:platforms] | Offer::APPLE_DEVICES
    (union.length - 3) == params[:staff_pick][:platforms].length || union.length == params[:staff_pick][:platforms].length
  end
end
