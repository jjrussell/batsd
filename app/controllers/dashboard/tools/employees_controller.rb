class Dashboard::Tools::EmployeesController < Dashboard::DashboardController
  layout 'tabbed'

  current_tab :tools
  filter_access_to :all

  before_filter :find_employee, :only => [ :edit, :update, :wfhs ]
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def index
    @employees = Employee.all_ordered
  end

  def new
    @employee = Employee.new
  end

  def edit
  end

  def create
    @employee = Employee.new(params[:employee])
    log_activity(@employee)

    if @employee.save
      if params[:upload_photo].blank?
        clear_photo(@employee)
      else
        @employee.save_photo!(params[:upload_photo].read)
      end
      flash[:notice] = 'Employee was successfully created.'
      redirect_to(edit_tools_employee_url(@employee))
    else
      render :action => "new"
    end
  end

  def update
    log_activity(@employee)
    if @employee.update_attributes(valid_params)
      unless params[:upload_photo].blank?
        @employee.save_photo!(params[:upload_photo].read)
      end
      flash[:notice] = 'Employee was successfully updated.'
      redirect_to(edit_tools_employee_url(@employee))
    else
      render :action => "edit"
    end
  end

  def delete_photo
    clear_photo(@employee)

    flash[:notice] = 'Employee photo was successfully removed.'
    redirect_to(edit_tools_employee_url(@employee))
  end

  def wfhs
    @wfhs = @employee.wfhs.today_and_after
  end

  private

  def clear_photo(employee)
    File.open("public/images/site/blank_image.jpg", 'rb') do |file|
      employee.save_photo!(file.read)
    end
  end

  def find_employee
    unless permitted_to?(:create, :dashboard_tools_employees)
      my_employee_id = current_user.employee.id
      redirect_to :id => my_employee_id unless params[:id] == my_employee_id
    end
    @employee = Employee.find(params[:id])
  end

  def valid_params
    if permitted_to?(:create, :dashboard_tools_employees)
      params[:employee]
    else
      safe_attributes = %w(
        first_name
        last_name
        title
        superpower
        current_games
        weapon
        biography
      )
      params[:employee].slice(*safe_attributes)
    end
  end
end
