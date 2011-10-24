class Tools::EditorsPicksController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :find_editors_pick , :only => [ :edit, :update, :activate, :expire ]
  after_filter :save_activity_logs, :only => [ :update, :activate, :expire ]

  def index
    @active_editors_picks   = EditorsPick.active.paginate(:page => params[:active_page], :per_page => 20)
    @upcoming_editors_picks = EditorsPick.upcoming.paginate(:page => params[:upcoming_page], :per_page => 10)
    @expired_editors_picks  = EditorsPick.expired.paginate(:page => params[:expired_page], :per_page => 10)
  end

  def new
    @editors_pick = EditorsPick.new
    @page_title = "New Editors' Pick"
    @button_name = "Create"
    render 'form'
  end

  def edit
    @page_title = "Edit Editors' Pick"
    @button_name = "Update"
    render 'form'
  end

  def show
    redirect_to edit_tools_editors_pick_path
  end

  def create
    @editors_pick = EditorsPick.new(params[:editors_pick])

    if @editors_pick.save
      flash[:notice] = 'EditorsPick was successfully created.'
      redirect_to tools_editors_picks_path
    else
      render :action => "form"
    end
  end

  def update
    safe_attributes = [:offer_id, :display_order, :description, :internal_notes, :scheduled_for ]
    if @editors_pick.safe_update_attributes(params[:editors_pick], safe_attributes)
      flash[:notice] = 'EditorsPick was successfully updated.'
      redirect_to([:tools, @editors_pick])
    else
      render :action => "form"
    end
  end

  def activate
    @editors_pick.scheduled_for = Time.zone.now
    @editors_pick.activate!
    redirect_to tools_editors_picks_path
  end

  def expire
    @editors_pick.expire!
    redirect_to tools_editors_picks_path
  end
private
  def find_editors_pick
    @editors_pick = EditorsPick.find(params[:id])
    log_activity(@editors_pick)
  end

end
