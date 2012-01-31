class Tools::FeaturedContentsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    now = Time.zone.now
    if params[:featured_type]
      @active_featured_contents   = FeaturedContent.active(now).for_featured_type(params[:featured_type]).ordered_by_date.paginate(:page => params[:active_page], :per_page => 20)
      @upcoming_featured_contents = FeaturedContent.upcoming(now).for_featured_type(params[:featured_type]).ordered_by_date.paginate(:page => params[:upcoming_page], :per_page => 10)
      @expired_featured_contents  = FeaturedContent.expired(now).for_featured_type(params[:featured_type]).ordered_by_date.paginate(:page => params[:expired_page], :per_page => 10)
    else
      @active_featured_contents   = FeaturedContent.active(now).ordered_by_date.paginate(:page => params[:active_page], :per_page => 20)
      @upcoming_featured_contents = FeaturedContent.upcoming(now).ordered_by_date.paginate(:page => params[:upcoming_page], :per_page => 10)
      @expired_featured_contents  = FeaturedContent.expired(now).ordered_by_date.paginate(:page => params[:expired_page], :per_page => 10)
    end
  end

  def new
    @featured_content = FeaturedContent.new
    @employees = Employee.active_by_first_name
  end

  def create
    @featured_content = FeaturedContent.new(params[:featured_content])
    @featured_content.author = Employee.find_by_id(params[:featured_content][:author_id]) if params[:featured_content][:author_id].present?
    if params[:featured_content][:offer_id].present?
      @featured_content.offer = Offer.find_in_cache(params[:featured_content][:offer_id])
    end
    @featured_content.main_icon_url = (@featured_content.author.get_photo_url(:source => :cloudfront)).gsub("#{RUN_MODE_PREFIX}tapjoy", "tapjoy") unless params[:featured_content][:featured_type] == FeaturedContent::TYPES_MAP[FeaturedContent::PROMO]
    @featured_content.secondary_icon_url = @featured_content.get_default_icon_url unless params[:featured_content][:featured_type] == FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK]

    if params[:featured_content][:start_date].present? && params[:featured_content][:end_date].present?
      unless params[:featured_content][:start_date].present? && params[:featured_content][:end_date].present? && date_validate?
        setup_before_render('End Date must be equal to or greater than Start Date.')
        render :action => :new
        return
      end
    end

    unless platforms_validate?
      setup_before_render("Please select at least one platform, and make sure include [#{Offer::APPLE_DEVICES.join(", ")}] for iOS platform.")
      render :action => :new
      return
    end

    if @featured_content.save
      @featured_content.save_icon!(params[:main_icon].read, "#{@featured_content.id}_main")  if params[:main_icon].present?
      @featured_content.save_icon!(params[:secondary_icon].read, "#{@featured_content.id}_secondary") if params[:secondary_icon].present?
      flash[:notice] = 'Featured content was successfully created.'
      redirect_to tools_featured_contents_path
    else
      setup_before_render('Cannot update, try again.')
      render :action => :new
    end
  end

  def edit
    @featured_content = FeaturedContent.find(params[:id])
    @employees = Employee.active_by_first_name
    if @featured_content.offer
      @search_result_name = @featured_content.offer.search_result_name
    end
  end

  def update
    @featured_content = FeaturedContent.find(params[:id])
    @featured_content.author = Employee.find_by_id(params[:featured_content][:author_id]) if params[:featured_content][:author_id].present?
    if params[:featured_content][:offer_id].present?
      @featured_content.offer = Offer.find_in_cache(params[:featured_content][:offer_id])
    end

    @featured_content.main_icon_url = (@featured_content.author.get_photo_url(:source => :cloudfront)).gsub("#{RUN_MODE_PREFIX}tapjoy", "tapjoy") unless params[:featured_content][:featured_type] == FeaturedContent::TYPES_MAP[FeaturedContent::PROMO]
    @featured_content.secondary_icon_url = @featured_content.get_default_icon_url unless params[:featured_content][:featured_type] == FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK]

    if params[:featured_content][:start_date].present? && params[:featured_content][:end_date].present?
      unless date_validate?
        setup_before_render('End Date must be equal to or greater than Start Date.')
        render :action => :edit, :id => params[:id]
        return
      end
    end

    unless platforms_validate?
      setup_before_render("Please select at least one platform, and make sure include [#{Offer::APPLE_DEVICES.join(", ")}] for iOS platform.")
      render :action => :edit, :id => params[:id]
      return
    end

    if @featured_content.update_attributes(params[:featured_content])
      @featured_content.save_icon!(params[:main_icon].read, "#{@featured_content.id}_main")  if params[:main_icon].present?
      @featured_content.save_icon!(params[:secondary_icon].read, "#{@featured_content.id}_secondary") if params[:secondary_icon].present?
      flash[:notice] = 'Featured content was successfully updated.'
      redirect_to tools_featured_contents_path
    else
      setup_before_render('Cannot update, try again.')
      render :action => :edit
    end
  end

  def destroy
    FeaturedContent.find(params[:id]).destroy
    redirect_to tools_featured_contents_path
  end

  private

  def setup_before_render(error_msg = nil)
    flash.now[:error] = @featured_content.errors[:offer] || error_msg
    @employees = Employee.active_by_first_name
    if params[:featured_content][:offer_id].present?
      @search_result_name = Offer.find_in_cache(params[:featured_content][:offer_id]).search_result_name
    end
  end

  def date_validate?
    Date.parse(params[:featured_content][:end_date]) >= Date.parse(params[:featured_content][:start_date])
  end

  def platforms_validate?
    union = params[:featured_content][:platforms] | Offer::APPLE_DEVICES
    real_len = params[:featured_content][:platforms].length
    real_len > 1 && ((union.length - 3) == real_len || union.length == real_len)
  end
end
