class Tools::EmployeesController < WebsiteController
  layout 'tabbed'

  current_tab :tools
  filter_access_to :all

  def index
    @employees = Employee.find(:all,
                               :order => 'display_order desc, last_name, first_name')
  end

  def new
    @employee = Employee.new
  end

  def edit
    @employee = Employee.find(params[:id])
  end

  def create
    @employee = Employee.new(params[:employee])
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
    @employee = Employee.find(params[:id])
    if @employee.update_attributes(params[:employee])
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
    @employee = Employee.find(params[:id])
    clear_photo(@employee)

    flash[:notice] = 'Employee photo was successfully removed.'
    redirect_to(edit_tools_employee_url(@employee))
  end

private

  def clear_photo(employee)
    File.open("public/images/site/blank_image.jpg", 'rb') do |file|
      employee.save_photo!(file.read)
    end
  end
end
