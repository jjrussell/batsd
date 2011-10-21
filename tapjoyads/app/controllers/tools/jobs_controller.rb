class Tools::JobsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_job, :only => [ :edit, :update, :destroy ]

  def index
    @jobs = Job.for_index
  end

  def new
    @job = Job.new
  end

  def create
    @job = Job.new(params[:job])
    if @job.save
      flash[:notice] = 'Successfully created job.'
      redirect_to :action => :index
    else
      render :action => :new
    end
  end

  def edit
  end

  def update
    if @job.update_attributes(params[:job])
      flash[:notice] = 'Successfully updated job.'
      redirect_to :action => :index
    else
      render :action => :new
    end
  end

  def destroy
    @job.destroy
    flash[:notice] = 'Successfully destroyed job.'
    redirect_to :action => :index
  end

private

  def find_job
    @job = Job.find(params[:id])
  end

end
