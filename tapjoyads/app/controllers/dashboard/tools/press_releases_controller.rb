class Dashboard::Tools::PressReleasesController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :find_press_release, :only => [ :edit, :update ]
  def index
    @press_releases = PressRelease.ordered
  end

  def new
    @press_release = PressRelease.new
    @press_release.seed_content_body

    render 'edit'
  end

  def create
    @press_release = PressRelease.new(params[:press_release])
    if @press_release.save
      flash[:notice] = "Press release added"
      redirect_to tools_press_releases_path
    else
      render :action => :new
    end
  end

  def edit
  end

  def update
    if @press_release.update_attributes(params[:press_release])
      flash[:notice] = "Press release saved"
      redirect_to tools_press_releases_path
    else
      render :action => :edit
    end
  end

  private

  def find_press_release
    @press_release = PressRelease.find(params[:id])
  end

end
