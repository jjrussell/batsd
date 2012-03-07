class Tools::WfhsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_wfh, :only => [ :show, :edit, :update, :destroy ]

  def index
    product_team = Employee.product_team
    grouped_team = product_team.group_by{ |employee| employee.location[0] }
    @team = grouped_team.keys.sort.map do |row_num|
      row = []
      grouped_team[row_num].each do |employee|
        row[employee.location.last] = employee
      end
      row
    end

    histogram       = product_team.map.histogram(&:first_name)
    first_names     = histogram.select{ |k, v| v > 1 }.map(&:first)
    @repeated_names = Set.new(first_names)

    @wfh_week       = Wfh.upcoming_week
    @wfh_today      = Wfh.today
    @not_here_today = @wfh_today.map(&:employee).uniq.sort_by(&:full_name)

    @wfhs = {}
    @wfh_today.each do |wfh|
      @wfhs[wfh.employee_id] ||= []
      @wfhs[wfh.employee_id] << wfh
    end
  end

  def new
    today = Date.today
    @wfh = Wfh.new(:start_date => today, :end_date => today)
    @wfhs = current_user.employee.wfhs.today_and_after
  end

  def edit
    @wfhs = current_user.employee.wfhs.today_and_after
  end

  def create
    params[:wfh][:employee_id] = current_user.employee.id
    @wfh = Wfh.new(params[:wfh])

    if @wfh.save
      redirect_to({ :action => 'index' }, :notice => 'Wfh was successfully created.')
    else
      render :action => "new"
    end
  end

  def update

    if @wfh.update_attributes(params[:wfh])
      redirect_to({ :action => 'index' }, :notice => 'Wfh was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @wfh.destroy

    redirect_to({ :action => 'index' }, :notice => 'Wfh was successfully deleted.')
  end

  private

  def find_wfh
    @wfh = current_user.employee.wfhs.find(params[:id])
  end
end
