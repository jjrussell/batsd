class Dashboard::Tools::ExperimentsController < Dashboard::DashboardController
  filter_resource_access

  before_filter(:except => [:index, :new, :create]) { @experiment = Experiment.find(params[:id]) }

  layout 'tabbed'
  current_tab :tools

  def index
    @experiments = Experiment.all # TODO paginate
  end

  def new
    @experiment = Experiment.new
  end

  def create
    @experiment = Experiment.new(params[:experiment].merge(:owner => current_user))

    if @experiment.invalid?
      flash[:error] = "There were errors creating the experiment.  Please correct your input and resubmit."
      render :new
    else
      @experiment.reserve_devices!
      @experiment.save
      redirect_to [:tools, @experiment]
    end
  end

  def show
  end

  def edit
  end

  def update
    @experiment.update_attributes(
      params[:experiment].slice(*@experiment.editable_attrs)
    )

    @experiment.save
    redirect_to [:tools, @experiment]
  end

  def destroy
    if @experiment.scheduled?
      @experiment.destroy
      flash[:notice] = 'Experiment was destroyed and devices freed'
    else
      flash[:notice] = 'Cannot destroy running or concluded experiments'
    end
    redirect_to tools_experiments_path
  end

  def start
    @experiment.start!
    redirect_to [:tools, @experiment]
  end

  def conclude
    @experiment.conclude!
    redirect_to [:tools, @experiment]
  end
end
