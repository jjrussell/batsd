class Dashboard::Tools::WfhsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_wfh, :only => [ :show, :edit, :update, :destroy ]

  def index
    products_team = Employee.products_team
    grouped_team = products_team.reject(&:deskless?).group_by{ |employee| employee.location[0] }
    @team = grouped_team.keys.sort.map do |row_num|
      row = []
      grouped_team[row_num].each do |employee|
        row[employee.location.last] = employee
      end
      row
    end

    histogram       = products_team.map.histogram(&:first_name)
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
      send_notification(@wfh, current_user.employee) if Rails.env.production?
      redirect_to_index('Wfh was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    safe_attributes = [ :category, :description, :start_date, :end_date ]
    if @wfh.safe_update_attributes(params[:wfh], safe_attributes)
      redirect_to_index('Wfh was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @wfh.destroy

    redirect_to_index('Wfh was successfully deleted.')
  end

  private

  def find_wfh
    @wfh = current_user.employee.wfhs.find(params[:id])
  end

  def redirect_to_index(notice)
    redirect_to({ :action => 'index' }, :notice => notice)
  end

  def send_notification(wfh, employee)
    data = wfh.notification_data
    data[:link] = tools_wfhs_url
    flowdock_api_url = "https://api.flowdock.com/v1/messages/team_inbox/#{FLOWDOCK_API_KEY}"
    Downloader.post(flowdock_api_url, data)
  end
end
